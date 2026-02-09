from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework import status, permissions
from rest_framework import generics
from .serializers import LoginSerializer
from .serializers import SignupSerializer
from .serializers import RestaurantSerializer
from .serializers import ClosestRestaurantsSerializer
from .serializers import CategorySerializer
from .serializers import MenuItemSerializer
from .serializers import CategoryMenuSerializer
from django.db import transaction
from django.utils import timezone
from .models import Restaurant, Category, Customer, Order, MenuItem
from .utils import haversine
from .serializers import OrderCreateSerializer
from .serializers import OrderReadSerializer
from .serializers import PaginationSerializer
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


class CompleteRestaurantProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            restaurant = Restaurant.objects.get(user=request.user)
        except Restaurant.DoesNotExist:
            return Response(
                {"error": "Access violation: not a restaurant"},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = RestaurantSerializer(restaurant, data=request.data, partial=True)
        print(serializer)
        if serializer.is_valid():
            serializer.save()
            return Response({
                "message": "Profile updated successfully",
                "profile_complete": serializer.data["profile_complete"]
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


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
        data["restaurant"] = restaurant.id  # enforce ownership

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


class ActiveRestaurantOrdersView(generics.ListAPIView):
    serializer_class = OrderReadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            restaurant = Restaurant.objects.get(user=self.request.user)
        except Restaurant.DoesNotExist:
            raise PermissionDenied("Only restaurants can access this endpoint.")

        return (
            Order.objects
            .filter(
                restaurant=restaurant,
                status__in=["accepted", "done"],
            )
            .select_related("customer")
            .prefetch_related("orderitem_set__item")
            .order_by("-created_at")
        )


class PendingRestaurantOrdersView(generics.ListAPIView):
    serializer_class = OrderReadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            restaurant = Restaurant.objects.get(user=self.request.user)
        except Restaurant.DoesNotExist:
            raise PermissionDenied("Only restaurants can access this endpoint.")

        return (
            Order.objects
            .filter(
                restaurant=restaurant,
                status__in=["pending"],
            )
            .select_related("customer")
            .prefetch_related("orderitem_set__item")
            .order_by("-created_at")
        )


class AllRestaurantOrdersView(generics.ListAPIView):
    serializer_class = OrderReadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            restaurant = Restaurant.objects.get(user=self.request.user)
        except Restaurant.DoesNotExist:
            raise PermissionDenied("Only restaurants can access this endpoint.")

        return (
            Order.objects
            .filter(restaurant=restaurant)
            .select_related("customer")
            .prefetch_related("orderitem_set__item")
            .order_by("-created_at")
        )

    def post(self, request, *args, **kwargs):
        try:
            restaurant = Restaurant.objects.get(user=request.user)
        except Restaurant.DoesNotExist:
            raise PermissionDenied("Only restaurants can access this endpoint.")

        serializer = PaginationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        index = serializer.validated_data["index"]
        count = serializer.validated_data["count"]

        queryset = (
            Order.objects
            .filter(restaurant=restaurant)
            .select_related("customer")
            .prefetch_related("orderitem_set__item")
            .order_by("-created_at")
        )

        # Manual pagination
        paginator = self.paginator
        paginator.page_size = count
        paginator.page = index + 1  # DRF pages are 1-based

        page = paginator.paginate_queryset(queryset, request, view=self)
        serialized = self.get_serializer(page, many=True)

        return paginator.get_paginated_response(serialized.data)
