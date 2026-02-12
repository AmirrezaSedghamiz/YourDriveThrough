from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework import status, permissions
from rest_framework import generics
from .serializers import CustomerSerializer, LoginSerializer, RatingCreateSerializer, RatingSerializer, RestaurantUpdateSerializer, UserSerializer
from .serializers import SignupSerializer
from .serializers import RestaurantSerializer
from .serializers import ClosestRestaurantsSerializer
from .serializers import CategorySerializer
from .serializers import MenuItemSerializer
from .serializers import RestaurantMenuRequestSerializer
from .serializers import RestaurantSearchSerializer
from django.db import transaction
from django.utils import timezone
from django.core.paginator import Paginator
from .models import Restaurant, Category, Customer, Order, MenuItem
from .utils import haversine
from .serializers import OrderCreateSerializer
from .serializers import OrderSerializer
from .serializers import MyOrdersFilterSerializer
from collections import defaultdict
from rest_framework.exceptions import NotFound
from drf_spectacular.utils import extend_schema
from django.shortcuts import get_object_or_404
from django.db.models import Case, When, IntegerField
import requests
from django.conf import settings


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

        # Reuse RestaurantSerializer for derived fields
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

        restaurants = Restaurant.objects.exclude(latitude=None).exclude(longitude=None)

        if not restaurants.exists():
            return Response({"results": [], "pagination": {}}, status=status.HTTP_200_OK)

        origins = "|".join([
            f"{r.latitude},{r.longitude}" for r in restaurants
        ])
        destinations = "|".join([
            f"{r.latitude},{r.longitude}" for r in restaurants
        ])

        url = "https://api.neshan.org/v1/distance-matrix?" + "type=car&origin=" + origins + "destinations=" + destinations

        headers = {"Api-Key": settings.NESHAN_API_KEY}

        try:
            response = requests.get(url, headers=headers, timeout=5)
            response.raise_for_status()
            data = response.json()
        except requests.RequestException as e:
            return Response({"detail": f"Error calling distance API: {str(e)}"},
                            status=status.HTTP_502_BAD_GATEWAY)

        durations = []
        if "rows" in data and len(data["rows"]) > 0:
            elements = data["rows"][0]["elements"]
            for r, elem in zip(restaurants, elements):
                duration = elem.get("duration", {}).get("value", float("inf"))  # seconds
                r.duration_seconds = duration
                durations.append((r, duration))
        else:
            for r in restaurants:
                r.duration_seconds = None
                durations.append((r, float("inf")))

        durations.sort(key=lambda x: x[1])
        ordered_restaurants = [r[0] for r in durations]

        paginator = Paginator(ordered_restaurants, page_size)
        page_obj = paginator.get_page(page)

        # Include duration in serialized results
        serialized_data = RestaurantSerializer(page_obj.object_list, many=True).data
        for r_obj, r_data in zip(page_obj.object_list, serialized_data):
            r_data["duration_seconds"] = getattr(r_obj, "duration_seconds", None)

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


@extend_schema(
    responses=CategorySerializer(many=True),
)
class GetCategoriesView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        categories = Category.objects.all()
        serializer = CategorySerializer(categories, many=True)
        return Response({"categories": serializer.data}, status=status.HTTP_200_OK)


class SaveMenuItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            restaurant = Restaurant.objects.get(user=request.user)
        except Restaurant.DoesNotExist:
            return Response(
                {"error": "Access violation: not a restaurant"},
                status=status.HTTP_403_FORBIDDEN
            )

        data = request.data.copy()
        data["restaurant"] = restaurant.id

        serializer = MenuItemSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
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
                restaurant=restaurant,
                is_active=True,
            )
            .prefetch_related("categories")
        )

        grouped = defaultdict(list)

        for item in items:
            categories = item.categories.all()
            if categories:
                for category in categories:
                    grouped[category.name].append(item)
            else:
                grouped["Uncategorized"].append(item)

        response_data = [
            {
                "category": category_name,
                "items": MenuItemSerializer(items, many=True).data,
            }
            for category_name, items in grouped.items()
        ]

        return Response(response_data, status=status.HTTP_200_OK)



class OrderCreateView(generics.CreateAPIView):
    serializer_class = OrderCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        customer = Customer.objects.get(user=self.request.user)

        with transaction.atomic():
            serializer.save(
                customer=customer,
                status="pending",
                created_at=timezone.now(),
            )


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

        # filter statuses if provided
        if statuses:
            queryset = queryset.filter(status__in=statuses)

            # custom ordering ONLY when statuses are provided
            status_ordering = Case(
                *[
                    When(status=status, then=pos)
                    for pos, status in enumerate(statuses)
                ],
                output_field=IntegerField(),
            )

            queryset = queryset.order_by(
                status_ordering,
                "-id",
            )
        else:
            # default ordering: newest first, no status grouping
            queryset = queryset.order_by("-id")

        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)

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
            "results": OrderSerializer(
                page_obj.object_list,
                many=True
            ).data
        })




class LeaveRatingView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not hasattr(request.user, "customer"):
            raise PermissionDenied("Only customers can leave ratings.")

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

        # Fetch order with ownership check
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

        # Terminal states cannot be changed
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

