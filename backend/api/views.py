import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.exceptions import NotFound
from rest_framework import serializers
from rest_framework import status, permissions
from rest_framework import generics
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Case, When, IntegerField
from django.db.models import Avg
from django.utils import timezone
from django.core.paginator import Paginator
from django.conf import settings
from drf_spectacular.utils import extend_schema
from collections import defaultdict
from .serializers import CustomerSerializer, CustomerUpdateSerializer, LoginSerializer, RatingCreateSerializer, RatingSerializer, MenuSyncSerializer, RestaurantUpdateSerializer, UserSerializer
from .serializers import SignupSerializer
from .serializers import RestaurantSerializer
from .serializers import ClosestRestaurantsSerializer
from .serializers import MenuItemSerializer
from .serializers import RestaurantMenuRequestSerializer
from .serializers import RestaurantSearchSerializer
from .serializers import MenuSyncSerializer
from .serializers import OrderCreateSerializer
from .serializers import OrderSerializer
from .serializers import ReorderSerializer
from .serializers import MyOrdersFilterSerializer
from .models import Rating, Restaurant, Category, Customer, Order, MenuItem, OrderItem


class MeAuthView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user

        response = {}

        response["phone"] = UserSerializer(user).data["phone"]

        if hasattr(user, "customer"):
            response["role"] = "customer"

        elif hasattr(user, "restaurant"):
            restaurant = user.restaurant
            response["role"] = "restaurant"
            response["profile_complete"] = all([
                restaurant.name,
                restaurant.address,
                restaurant.latitude,
                restaurant.longitude,
            ])

        else:
            raise PermissionDenied("User has no valid role.")

        return Response(response, status=status.HTTP_200_OK)


@extend_schema(
    request=LoginSerializer,
)
class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        print(serializer.errors)
        return Response(serializer.errors, status=status.HTTP_403_FORBIDDEN)

@extend_schema(
    request=SignupSerializer,
)
class SignupView(APIView):
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            result = serializer.save()
            return Response(result, status=status.HTTP_201_CREATED)
        print(serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class MeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user

        data = {
            "user": UserSerializer(user).data,
        }

        if hasattr(user, "restaurant"):
            data["role"] = "restaurant"
            data["restaurant"] = RestaurantSerializer(user.restaurant).data

        elif hasattr(user, "customer"):
            data["role"] = "customer"
            data["customer"] = CustomerSerializer(user.customer).data

        else:
            data["role"] = "unknown"

        return Response(data)


class RestaurantMeUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        response = self.patch(request)
        response.headers["X-Deprecated"] = "Use PATCH /me/restaurant/"
        return response

    def patch(self, request):
        if not hasattr(request.user, "restaurant"):
            raise PermissionDenied("Only restaurants can update this.")

        restaurant = request.user.restaurant

        serializer = RestaurantUpdateSerializer(
            restaurant,
            data=request.data,
            partial=True
        )

        serializer.is_valid(raise_exception=True)
        serializer.save()

        response_data = serializer.data
        response_data["profile_complete"] = all([
            restaurant.name,
            restaurant.address,
            restaurant.latitude,
            restaurant.longitude,
        ])

        return Response(response_data)

@extend_schema(
    request=ClosestRestaurantsSerializer,
    responses=RestaurantSerializer(many=True),
)
class GetClosestRestaurantsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ClosestRestaurantsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        lat = serializer.validated_data["latitude"]
        lon = serializer.validated_data["longitude"]
        page = serializer.validated_data["page"]
        page_size = serializer.validated_data["page_size"]

        restaurants = (
        Restaurant.objects
            .filter(
                latitude__isnull=False,
                longitude__isnull=False,
                latitude__gte=0,
                longitude__gte=0,
            )
        )

        if not restaurants.exists():
            return Response({"results": [], "pagination": {}}, status=status.HTTP_200_OK)

        # --- Neshan API Call ---
        origins = f"{lat},{lon}"
        destinations = "|".join([
            f"{float(r.latitude):.6f},{float(r.longitude):.6f}"
            for r in restaurants
        ])
        url = f"https://api.neshan.org/v1/distance-matrix?type=car&origins={origins}&destinations={destinations}"
        headers = {"Api-Key": settings.NESHAN_API_KEY}

        try:
            response = requests.get(url, headers=headers, timeout=5)
            response.raise_for_status()
            data = response.json()
        except requests.RequestException as e:
            return Response({"detail": f"Error calling distance API: {str(e)}"},
                            status=status.HTTP_502_BAD_GATEWAY)

        # --- Attach duration ---
        durations = []
        if "rows" in data and len(data["rows"]) > 0:
            elements = data["rows"][0]["elements"]
            for r, elem in zip(restaurants, elements):
                duration = elem.get("duration", {}).get("value", None)  # seconds
                r.duration_seconds = duration
                durations.append((r, duration if duration is not None else float("inf")))
        else:
            for r in restaurants:
                r.duration_seconds = None
                durations.append((r, float("inf")))

        # Sort by duration
        durations.sort(key=lambda x: x[1])
        ordered_restaurants = [r[0] for r in durations]

        # Pagination
        paginator = Paginator(ordered_restaurants, page_size)
        page_obj = paginator.get_page(page)

        # --- Compute average rating per restaurant ---
        # Get restaurant IDs on this page
        restaurant_ids = [r.id for r in page_obj.object_list]

        # Compute average ratings in one query
        avg_ratings = (
            Order.objects
            .filter(restaurant_id__in=restaurant_ids, rating__isnull=False)
            .values("restaurant_id")
            .annotate(avg_rating=Avg("rating__number"))
        )
        avg_rating_map = {item["restaurant_id"]: item["avg_rating"] for item in avg_ratings}

        # Serialize restaurants and attach duration + average rating
        serialized_data = RestaurantSerializer(page_obj.object_list, many=True).data
        for r_obj, r_data in zip(page_obj.object_list, serialized_data):
            r_data["duration_seconds"] = getattr(r_obj, "duration_seconds", None)
            r_data["average_rating"] = avg_rating_map.get(r_obj.id)

        return Response({
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_pages": paginator.num_pages,
                "total_items": paginator.count,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
            },
            "results": serialized_data
        }, status=status.HTTP_200_OK)


class SaveMenuItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Ensure the user is a restaurant
        try:
            restaurant = request.user.restaurant
        except Restaurant.DoesNotExist:
            return Response(
                {"error": "Access violation: not a restaurant"},
                status=status.HTTP_403_FORBIDDEN
            )

        data = request.data.copy()

        # Ensure category belongs to this restaurant
        category_id = data.get("category")
        try:
            category = Category.objects.get(id=category_id, restaurant=restaurant)
        except (Category.DoesNotExist, TypeError):
            return Response(
                {"error": "Invalid category or category does not belong to you"},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = MenuItemSerializer(data=data)
        if serializer.is_valid():
            serializer.save(category=category)
            return Response(
                {"message": "Menu item created successfully", "item": serializer.data},
                status=status.HTTP_201_CREATED
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RestaurantMenuGroupedView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = RestaurantMenuRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        restaurant_id = serializer.validated_data["restaurant_id"]

        try:
            restaurant = Restaurant.objects.get(id=restaurant_id)
        except Restaurant.DoesNotExist:
            raise NotFound("Restaurant not found.")

        items = (
            MenuItem.objects
            .filter(
                category__restaurant=restaurant,
                is_active=True
            )
            .select_related("category")
        )

        grouped = defaultdict(list)

        for item in items:
            if item.category:
                key = item.category.id
            else:
                key = None
            grouped[key].append(item)

        response_data = []

        for category_id, category_items in grouped.items():
            if category_id is None:
                category_name = "Uncategorized"
            else:
                category_name = category_items[0].category.name

            response_data.append({
                "id": category_id,
                "category": category_name,
                "items": MenuItemSerializer(category_items, many=True).data,
            })

        return Response(response_data, status=status.HTTP_200_OK)


class OrderCreateView(generics.CreateAPIView):
    serializer_class = OrderCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        if not hasattr(self.request.user, "customer"):
            raise PermissionDenied("Only customers can create orders.")

        serializer.save()



# DEPRECATED: Use POST /me/orders/ with statuses=["accepted","done"]
class ActiveRestaurantOrdersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        response = MyOrdersView()._handle(
            request,
            forced_statuses=["accepted", "done"]
        )
        response.headers["X-Deprecated"] = "Use POST /me/orders/"
        return response


# DEPRECATED: Use POST /me/orders/ with statuses=["pending"]
class PendingRestaurantOrdersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        response = MyOrdersView()._handle(
            request,
            forced_statuses=["pending"]
        )
        response.headers["X-Deprecated"] = "Use POST /me/orders/"
        return response


# DEPRECATED: Use POST /me/orders/
class AllRestaurantOrdersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        response = MyOrdersView()._handle(request)
        response.headers["X-Deprecated"] = "Use POST /me/orders/"
        return response

    def post(self, request):
        response = MyOrdersView()._handle(request)
        response.headers["X-Deprecated"] = "Use POST /me/orders/"
        return response

DEFAULT_STATUS_ORDER = [#Unused.
    "pending",
    "accepted",
    "done",
    "failed",
    "recieved",
    "canceled",
]

@extend_schema(
    responses=OrderSerializer(many=True)
)
class MyOrdersView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        filter_serializer = MyOrdersFilterSerializer(data=request.data)
        filter_serializer.is_valid(raise_exception=True)

        statuses = filter_serializer.validated_data.get("statuses")
        page = filter_serializer.validated_data["page"]
        page_size = filter_serializer.validated_data["page_size"]

        user = request.user

        # role-based queryset
        if hasattr(user, "customer"):
            queryset = Order.objects.filter(customer=user.customer)
            role = "customer"

        elif hasattr(user, "restaurant"):
            queryset = Order.objects.filter(restaurant=user.restaurant)
            role = "restaurant"

        else:
            raise PermissionDenied("User has no valid role.")

        if statuses:
            queryset = queryset.filter(status__in=statuses)
            status_ordering = Case(
                *[When(status=status, then=pos) for pos, status in enumerate(statuses)],
                output_field=IntegerField(),
            )
            queryset = queryset.order_by(status_ordering, "-id")
        else:
            queryset = queryset.order_by("-id")

        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)
        orders = list(page_obj.object_list)

        order_ids = [o.id for o in orders]
        ratings_map = {
            r.order_id: r for r in Rating.objects.filter(order_id__in=order_ids)
        }

        serialized_orders = OrderSerializer(orders, many=True).data

        for order_obj, order_data in zip(orders, serialized_orders):
            rating = ratings_map.get(order_obj.id)
            if rating:
                order_data["rating"] = {
                    "id": rating.id,
                    "number": rating.number,
                }
            else:
                order_data["rating"] = None

        return Response({
            "role": role,
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_pages": paginator.num_pages,
                "total_items": paginator.count,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
            },
            "results": serialized_orders
        })


class LeaveRatingView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = RatingCreateSerializer(
            data=request.data,
            context={"request": request}
        )
        serializer.is_valid(raise_exception=True)

        rating = serializer.save()

        return Response(
            RatingSerializer(rating).data,
            status=status.HTTP_201_CREATED
        )


class OrderStatusUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    CUSTOMER_TRANSITIONS = {
        "pending": ["canceled"],
        "accepted": ["canceled"],
        "done": ["recieved"],
    }

    RESTAURANT_TRANSITIONS = {
        "pending": ["accepted", "failed"],
        "accepted": ["done", "failed"],
    }

    TERMINAL_STATES = {"canceled", "failed", "recieved"}

    def post(self, request):
        order_id = request.data.get("order_id")
        new_status = request.data.get("new_status")

        if not order_id or not new_status:
            return Response(
                {"detail": "order_id and new_status are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = request.user

        if hasattr(user, "customer"):
            order = get_object_or_404(
                Order,
                id=order_id,
                customer=user.customer,
            )
            transitions = self.CUSTOMER_TRANSITIONS

        elif hasattr(user, "restaurant"):
            order = get_object_or_404(
                Order,
                id=order_id,
                restaurant=user.restaurant,
            )
            transitions = self.RESTAURANT_TRANSITIONS

        else:
            raise PermissionDenied("User has no valid role.")

        current_status = order.status

        if current_status in self.TERMINAL_STATES:
            return Response(
                {"detail": "Order can no longer be modified"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        allowed_next = transitions.get(current_status, [])

        if new_status not in allowed_next:
            return Response(
                {
                    "detail": "Invalid status transition",
                    "current_status": current_status,
                    "allowed_next": allowed_next,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        order.status = new_status
        order.save(update_fields=["status"])

        return Response(
            {
                "message": "Order status updated successfully",
                "order": OrderSerializer(order).data,
            },
            status=status.HTTP_200_OK,
        )


class RestaurantSearchView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = RestaurantSearchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query = serializer.validated_data.get("query", "")
        page = serializer.validated_data["page"]
        page_size = serializer.validated_data["page_size"]

        queryset = Restaurant.objects.filter(is_open=True)

        if query:
            queryset = queryset.filter(
                name__icontains=query
            )

        queryset = queryset.order_by("name")

        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)

        return Response({
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_pages": paginator.num_pages,
                "total_items": paginator.count,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
            },
            "results": RestaurantSerializer(
                page_obj.object_list,
                many=True
            ).data
        }, status=status.HTTP_200_OK)


class OrderRatingView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get("order_id")

        if not order_id:
            return Response(
                {"detail": "order_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user

        try:
            if hasattr(user, "customer"):
                order = Order.objects.get(
                    id=order_id,
                    customer=user.customer
                )
            elif hasattr(user, "restaurant"):
                order = Order.objects.get(
                    id=order_id,
                    restaurant=user.restaurant
                )
            else:
                raise PermissionDenied("User has no valid role.")
        except Order.DoesNotExist:
            raise NotFound("Order not found or not accessible.")

        try:
            rating = order.rating
        except Rating.DoesNotExist:
            return Response(
                {
                    "order_id": order.id,
                    "rated": False,
                    "rating": None
                },
                status=status.HTTP_200_OK
            )

        return Response(
            {
                "order_id": order.id,
                "rated": True,
                "rating": RatingSerializer(rating).data
            },
            status=status.HTTP_200_OK
        )


class MeMenuSyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        if not hasattr(request.user, "restaurant"):
            raise PermissionDenied("Only restaurants can sync menu.")

        restaurant = request.user.restaurant

        serializer = MenuSyncSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        incoming_categories = serializer.validated_data["categories"]

        existing_categories = {
            c.id: c for c in Category.objects.filter(
                restaurant=restaurant,
                is_active=True
            )
        }

        existing_items = {
            i.id: i for i in MenuItem.objects.filter(
                category__restaurant=restaurant,
                is_active=True
            ).select_related("category")
        }

        seen_category_ids = set()
        seen_item_ids = set()

        for cat_data in incoming_categories:
            cat_id = cat_data.get("id")
            items_data = cat_data["items"]

            if cat_id:
                category = existing_categories.get(cat_id)
                if not category:
                    raise PermissionDenied("Invalid category id for this restaurant.")

                category.name = cat_data["name"]
                category.is_active = True
                category.save(update_fields=["name", "is_active"])
                seen_category_ids.add(category.id)
            else:
                category = Category.objects.create(
                    restaurant=restaurant,
                    name=cat_data["name"],
                    is_active=True
                )
                seen_category_ids.add(category.id)

            for item_data in items_data:
                item_id = item_data.get("id")

                if item_id:
                    item = existing_items.get(item_id)
                    if not item:
                        raise PermissionDenied("Invalid menu item id for this restaurant.")

                    item.name = item_data["name"]
                    item.description = item_data["description"]
                    item.price = item_data["price"]
                    item.expected_duration = item_data["expected_duration"]
                    item.category = category
                    item.is_active = item_data.get("is_active", True)
                    item.save()
                    seen_item_ids.add(item.id)
                else:
                    item = MenuItem.objects.create(
                        category=category,
                        name=item_data["name"],
                        description=item_data["description"],
                        price=item_data["price"],
                        expected_duration=item_data["expected_duration"],
                        is_active=True,
                    )
                    seen_item_ids.add(item.id)

        for item_id, item in existing_items.items():
            if item_id not in seen_item_ids:
                item.is_active = False
                item.save(update_fields=["is_active"])

        for cat_id, category in existing_categories.items():
            if cat_id not in seen_category_ids:
                category.is_active = False
                category.save(update_fields=["is_active"])

        return Response(
            {"message": "Menu synced successfully"},
            status=status.HTTP_200_OK
        )


class ReorderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _get_neshan_duration(self, origin_lat, origin_lon, dest_lat, dest_lon):
        if origin_lat < 0 or origin_lon < 0 or dest_lat < 0 or dest_lon < 0:
            return 0

        url = (
            "https://api.neshan.org/v1/distance-matrix"
            f"?type=car&origins={origin_lat},{origin_lon}"
            f"&destinations={dest_lat},{dest_lon}"
        )
        headers = {"Api-Key": settings.NESHAN_API_KEY}

        try:
            response = requests.get(url, headers=headers, timeout=5)
            response.raise_for_status()
            data = response.json()
            return data["rows"][0]["elements"][0]["duration"]["value"]
        except Exception:
            return 0

    def post(self, request):
        serializer = ReorderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        order_id = serializer.validated_data["order_id"]
        lat = serializer.validated_data["latitude"]
        lon = serializer.validated_data["longitude"]
        allow_partial = serializer.validated_data["allow_partial"]

        # Only customers can reorder
        if not hasattr(request.user, "customer"):
            return Response(
                {"detail": "Only customers can reorder."},
                status=status.HTTP_403_FORBIDDEN,
            )

        customer = request.user.customer

        old_order = get_object_or_404(
            Order.objects.prefetch_related("orderitem_set__item"),
            id=order_id,
            customer=customer,
        )

        restaurant = old_order.restaurant

        if not getattr(restaurant, "is_open", True):
            return Response(
                {"detail": "Restaurant is currently closed."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        old_items = old_order.orderitem_set.all()

        unavailable_items = []
        valid_items = []

        for order_item in old_items:
            menu_item = order_item.item
            if not menu_item.is_active:
                unavailable_items.append({
                    "id": menu_item.id,
                    "name": menu_item.name,
                })
            else:
                valid_items.append(order_item)

        if not allow_partial and unavailable_items:
            return Response(
                {
                    "detail": "Cannot reorder because some items are unavailable.",
                    "unavailable_items": unavailable_items,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not valid_items:
            return Response(
                {
                    "detail": "None of the items are available anymore.",
                    "unavailable_items": unavailable_items,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        total = 0
        max_prep_duration = 0

        for order_item in valid_items:
            menu_item = order_item.item
            qty = order_item.quantity
            total += menu_item.price * qty
            max_prep_duration = max(max_prep_duration, menu_item.expected_duration)

        travel_duration = self._get_neshan_duration(
            lat, lon, float(restaurant.latitude), float(restaurant.longitude)
        )

        expected_arrival_time = (max_prep_duration * 60) + travel_duration

        with transaction.atomic():
            new_order = Order.objects.create(
                customer=customer,
                restaurant=restaurant,
                start=timezone.now(),
                status="pending",
                total=total,
                expected_duration=max_prep_duration,
                expected_arrival_time=expected_arrival_time,
            )

            for old_item in valid_items:
                OrderItem.objects.create(
                    order=new_order,
                    item=old_item.item,
                    quantity=old_item.quantity,
                    special=old_item.special,
                )

        response_data = {
            "message": "Order recreated successfully",
            "order": OrderSerializer(new_order).data,
        }

        if unavailable_items and allow_partial:
            response_data["warning"] = "Some items were unavailable and were not included"
            response_data["unavailable_items"] = unavailable_items

        return Response(response_data, status=status.HTTP_201_CREATED)


class GetClosestRestaurants2View(APIView):
    permission_classes = [permissions.AllowAny]

    class InputSerializer(serializers.Serializer):
        lat1 = serializers.FloatField()
        lon1 = serializers.FloatField()
        lat2 = serializers.FloatField()
        lon2 = serializers.FloatField()
        page = serializers.IntegerField(default=1)
        page_size = serializers.IntegerField(default=10)

    def post(self, request):
        serializer = self.InputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        lat1 = serializer.validated_data["lat1"]
        lon1 = serializer.validated_data["lon1"]
        lat2 = serializer.validated_data["lat2"]
        lon2 = serializer.validated_data["lon2"]
        page = serializer.validated_data["page"]
        page_size = serializer.validated_data["page_size"]

        restaurants = (
            Restaurant.objects
            .filter(latitude__isnull=False, longitude__isnull=False)
            .filter(latitude__gte=0, longitude__gte=0)
        )

        if not restaurants.exists():
            return Response({"results": [], "pagination": {}}, status=status.HTTP_200_OK)

        # --- Neshan API Call ---
        origins = f"{lat1},{lon1}|{lat2},{lon2}"
        destinations = "|".join([
            f"{float(r.latitude):.6f},{float(r.longitude):.6f}" for r in restaurants
        ])
        url = f"https://api.neshan.org/v1/distance-matrix?type=car&origins={origins}&destinations={destinations}"
        headers = {"Api-Key": settings.NESHAN_API_KEY}

        try:
            response = requests.get(url, headers=headers, timeout=5)
            response.raise_for_status()
            data = response.json()
        except requests.RequestException as e:
            return Response({"detail": f"Error calling distance API: {str(e)}"},
                            status=status.HTTP_502_BAD_GATEWAY)

        # --- Compute total duration per restaurant ---
        durations = []
        if "rows" in data and len(data["rows"]) == 2:
            for idx, r in enumerate(restaurants):
                # sum of durations from both origins
                total_duration = 0
                for row in data["rows"]:
                    elem = row["elements"][idx]
                    duration = elem.get("duration", {}).get("value", float("inf"))
                    total_duration += duration if duration is not None else float("inf")
                r.total_duration_seconds = total_duration
                durations.append((r, total_duration))
        else:
            for r in restaurants:
                r.total_duration_seconds = None
                durations.append((r, float("inf")))

        # Sort by total duration
        durations.sort(key=lambda x: x[1])
        ordered_restaurants = [r[0] for r in durations]

        # Pagination
        paginator = Paginator(ordered_restaurants, page_size)
        page_obj = paginator.get_page(page)

        # --- Compute average rating per restaurant ---
        restaurant_ids = [r.id for r in page_obj.object_list]
        avg_ratings = (
            Order.objects
            .filter(restaurant_id__in=restaurant_ids, rating__isnull=False)
            .values("restaurant_id")
            .annotate(avg_rating=Avg("rating__number"))
        )
        avg_rating_map = {item["restaurant_id"]: item["avg_rating"] for item in avg_ratings}

        # Serialize restaurants and attach total duration + average rating
        serialized_data = RestaurantSerializer(page_obj.object_list, many=True).data
        for r_obj, r_data in zip(page_obj.object_list, serialized_data):
            r_data["total_duration_seconds"] = getattr(r_obj, "total_duration_seconds", None)
            r_data["average_rating"] = avg_rating_map.get(r_obj.id)

        return Response({
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_pages": paginator.num_pages,
                "total_items": paginator.count,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
            },
            "results": serialized_data
        }, status=status.HTTP_200_OK)


class CustomerMeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        try:
            customer = user.customer
        except Customer.DoesNotExist:
            return Response({"detail": "Customer profile not found."}, status=404)

        return Response({
            "phone": user.phone,
            "image": customer.image.url if customer.image else None,
        })


class CustomerUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            customer = request.user.customer
        except Customer.DoesNotExist:
            return Response({"detail": "Customer profile not found."}, status=404)

        serializer = CustomerUpdateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data

        # Update phone if provided
        if "phone" in data:
            request.user.phone = data["phone"]
            request.user.save(update_fields=["phone"])

        # Update image if provided
        if "image" in data:
            customer.image = data["image"]
            customer.save(update_fields=["image"])

        return Response({
            "message": "Customer info updated successfully",
            "phone": request.user.phone,
            "image": customer.image.url if customer.image else None,
        }, status=status.HTTP_200_OK)
