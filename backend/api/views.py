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
from .serializers import CategoryMenuSerializer
from django.db import transaction
from django.utils import timezone
from django.core.paginator import Paginator
from .models import Restaurant, Category, Customer, Order, MenuItem
from .utils import haversine
from .serializers import OrderCreateSerializer
from .serializers import OrderSerializer
from .serializers import PaginationSerializer
from .serializers import MyOrdersFilterSerializer
from collections import defaultdict
from rest_framework.exceptions import NotFound



class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        print(serializer.errors)
        return Response(serializer.errors, status=status.HTTP_403_FORBIDDEN)


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

        return Response(serializer.data)


class GetClosestRestaurantsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ClosestRestaurantsSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        lat = serializer.validated_data["latitude"]
        lon = serializer.validated_data["longitude"]
        index = serializer.validated_data["index"]
        count = serializer.validated_data["count"]

        restaurants = Restaurant.objects.exclude(latitude=None).exclude(longitude=None)

        # Compute distances
        distances = []
        for r in restaurants:
            dist = haversine(lat, lon, float(r.latitude), float(r.longitude))
            distances.append((r, dist))

        # Sort by distance
        distances.sort(key=lambda x: x[1])

        # Apply pagination
        selected = distances[index:index+count]
        selected_restaurants = [r[0] for r in selected]

        # Serialize full info
        serializer = RestaurantSerializer(selected_restaurants, many=True)
        return Response({"restaurants": serializer.data}, status=status.HTTP_200_OK)


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

    def get(self, request, restaurant_id):
        if not Restaurant.objects.filter(id=restaurant_id).exists():
            raise NotFound("Restaurant not found.")

        items = (
            MenuItem.objects
            .filter(
                restaurant_id=restaurant_id,
                is_active=True,
            )
            .prefetch_related("categories")
        )

        grouped = defaultdict(list)

        for item in items:
            if item.categories.exists():
                for category in item.categories.all():
                    grouped[category.name].append(item)
            else:
                grouped["Uncategorized"].append(item)

        response_data = [
            {
                "category": category,
                "items": MenuItemSerializer(items, many=True).data,
            }
            for category, items in grouped.items()
        ]

        return Response(
            CategoryMenuSerializer(response_data, many=True).data
        )


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
            queryset = Order.objects.filter(
                customer=user.customer
            )

        elif hasattr(user, "restaurant"):
            queryset = Order.objects.filter(
                restaurant=user.restaurant
            )

        else:
            raise PermissionDenied("User has no valid role.")

        if statuses:
            queryset = queryset.filter(status__in=statuses)

        queryset = queryset.order_by("-id")

        paginator = Paginator(queryset, page_size)
        page_obj = paginator.get_page(page)

        return Response({
            "role": "customer" if hasattr(user, "customer") else "restaurant",
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
