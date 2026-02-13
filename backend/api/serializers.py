from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant, Category, MenuItem, Order, OrderItem, Rating
from .exceptions import RoleNotFound
from django.utils import timezone
from django.conf import settings
import requests




User = get_user_model()

class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data["phone"], password=data["password"])
        if not user:
            raise serializers.ValidationError({"error": "Invalid credentials"})

        role = None
        profile_complete = None

        if Customer.objects.filter(user=user).exists():
            role = "customer"

        elif Restaurant.objects.filter(user=user).exists():
            role = "restaurant"
            restaurant = Restaurant.objects.get(user=user)
            profile_complete = all([
                restaurant.name,
                restaurant.address,
                restaurant.latitude,
                restaurant.longitude,
            ])

        else:
            raise RoleNotFound()

        refresh = RefreshToken.for_user(user)
        response = {
            "access_token": str(refresh.access_token),
            "refresh_token": str(refresh),
            "role": role,
        }
        if role == "restaurant":
            response["profile_complete"] = profile_complete

        return response


class SignupSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=["customer", "restaurant"])

    def validate_phone(self, value):
        if User.objects.filter(phone=value).exists():
            raise serializers.ValidationError({"error": "Phone number already registered"})
        return value

    def create(self, validated_data):
        role = validated_data.pop("role")
        password = validated_data.pop("password")
        phone = validated_data.pop("phone")

        user = User.objects.create(phone=phone)
        user.set_password(password)
        user.save()

        if role == "customer":
            Customer.objects.create(user=user)
        elif role == "restaurant":
            Restaurant.objects.create(user=user)

        refresh = RefreshToken.for_user(user)
        return {
            "access_token": str(refresh.access_token),
            "refresh_token": str(refresh),
        }


class RestaurantSerializer(serializers.ModelSerializer):
    profile_complete = serializers.SerializerMethodField()

    class Meta:
        model = Restaurant
        fields = (
            "id",
            "name",
            "address",
            "latitude",
            "longitude",
            "image",
            "is_open",
            "profile_complete",
        )

    def get_profile_complete(self, obj):
        return all([
            obj.name,
            obj.address,
            obj.latitude,
            obj.longitude,
        ])


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "phone",
            "is_active",
            "last_login",
        )


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = ("id",)


class RestaurantUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Restaurant
        fields = (
            "name",
            "address",
            "latitude",
            "longitude",
            "image",
            "is_open",
        )


class ClosestRestaurantsSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    page = serializers.IntegerField(min_value=1)
    page_size = serializers.IntegerField(min_value=1, max_value=50)


class CategorySerializer(serializers.ModelSerializer):
    restaurant_id = serializers.IntegerField(source="restaurant.id", read_only=True)

    class Meta:
        model = Category
        fields = ["id", "name", "restaurant_id"]


class MenuItemSerializer(serializers.ModelSerializer):
    category_id = serializers.IntegerField(source="category.id", read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = MenuItem
        fields = [
            "id",
            "category_id",
            "category_name",
            "name",
            "description",
            "price",
            "expected_duration",
            "image",
            "is_active",
        ]


class OrderItemCreateSerializer(serializers.Serializer):
    menu_item = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)
    special = serializers.CharField(required=False, allow_blank=True)

class OrderCreateSerializer(serializers.ModelSerializer):
    items = OrderItemCreateSerializer(many=True)

    latitude = serializers.FloatField(write_only=True)
    longitude = serializers.FloatField(write_only=True)

    class Meta:
        model = Order
        fields = ("restaurant", "items", "latitude", "longitude")

    def validate(self, data):
        items = data.get("items", [])
        restaurant = data["restaurant"]

        if not items:
            raise serializers.ValidationError("Order must have at least one item.")

        item_ids = [i.get("menu_item") for i in items if i.get("menu_item") is not None]

        menu_items = MenuItem.objects.filter(
            id__in=item_ids,
            is_active=True,
            category__restaurant=restaurant,
        )

        if menu_items.count() != len(item_ids):
            raise serializers.ValidationError(
                "All items must belong to the restaurant and be active."
            )

        return data

    def _get_neshan_duration(self, origin_lat, origin_lon, dest_lat, dest_lon):
        """
        Returns duration in seconds using Neshan Distance Matrix API.
        Falls back to 0 if API fails.
        """
        if (
            origin_lat < 0 or origin_lon < 0 or
            dest_lat < 0 or dest_lon < 0
        ):
            return 0

        url = (
            "https://api.neshan.org/v1/distance-matrix"
            f"?type=car&origins={origin_lat:.6f},{origin_lon:.6f}"
            f"&destinations={dest_lat:.6f},{dest_lon:.6f}"
        )

        headers = {
            "Api-Key": settings.NESHAN_API_KEY
        }

        try:
            response = requests.get(url, headers=headers, timeout=5)
            response.raise_for_status()
            data = response.json()

            return data["rows"][0]["elements"][0]["duration"]["value"]

        except Exception:
            return 0

    def create(self, validated_data):
        items_data = validated_data.pop("items")
        origin_lat = validated_data.pop("latitude")
        origin_lon = validated_data.pop("longitude")
        restaurant = validated_data["restaurant"]

        total = 0
        max_duration = 0

        menu_items = {
            item.id: item
            for item in MenuItem.objects.filter(
                id__in=[i["menu_item"] for i in items_data]
            )
        }

        for item in items_data:
            menu_item = menu_items[item["menu_item"]]
            qty = item["quantity"]

            total += menu_item.price * qty
            max_duration = max(max_duration, menu_item.expected_duration)

        travel_duration = self._get_neshan_duration(
            origin_lat,
            origin_lon,
            float(restaurant.latitude),
            float(restaurant.longitude),
        )

        expected_arrival_time = travel_duration

        validated_data = validated_data.copy()
        validated_data.pop("restaurant", None)
        validated_data.pop("total", None)
        validated_data.pop("start", None)
        validated_data.pop("expected_duration", None)
        validated_data.pop("expected_arrival_time", None)

        order = Order.objects.create(
            restaurant=restaurant,
            expected_duration=max_duration,
            expected_arrival_time=expected_arrival_time,
            total=total,
            start=timezone.now(),
            **validated_data,
        )

        for item in items_data:
            OrderItem.objects.create(
                order=order,
                item=menu_items[item["menu_item"]],
                quantity=item["quantity"],
                special=item.get("special", ""),
            )

        return order


class OrderItemSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="item.name", read_only=True)
    price = serializers.IntegerField(source="item.price", read_only=True)

    class Meta:
        model = OrderItem
        fields = (
            "id",
            "item",
            "item_name",
            "price",
            "quantity",
            "special",
        )


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(
        source="orderitem_set",
        many=True,
        read_only=True
    )
    restaurant_name = serializers.CharField(source="restaurant.name", read_only=True)
    customer_phone = serializers.CharField(source="customer.user.phone", read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "status",
            "total",
            "start",
            "expected_duration",
            "expected_arrival_time",
            "restaurant_name",
            "customer_phone",
            "items",
        )


class CategoryMenuSerializer(serializers.Serializer):
    category = serializers.CharField()
    items = MenuItemSerializer(many=True)


class PaginationSerializer(serializers.Serializer):
    index = serializers.IntegerField(min_value=0)
    count = serializers.IntegerField(min_value=1, max_value=50)


class MyOrdersFilterSerializer(serializers.Serializer):
    statuses = serializers.ListField(
        child=serializers.CharField(),
        required=False
    )
    page = serializers.IntegerField(min_value=1, required=False, default=1)
    page_size = serializers.IntegerField(
        min_value=1,
        max_value=100,
        required=False,
        default=10
    )


class RatingCreateSerializer(serializers.Serializer):
    order = serializers.IntegerField()
    number = serializers.IntegerField(min_value=1, max_value=5)

    def validate(self, data):
        request = self.context["request"]
        order_id = data["order"]

        try:
            order = Order.objects.get(id=order_id)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order does not exist.")

        if not hasattr(request.user, "customer") or order.customer != request.user.customer:
            raise serializers.ValidationError("You can only rate your own orders.")

        if hasattr(order, "rating"):
            raise serializers.ValidationError("This order has already been rated.")

        if order.status not in ["done", "recieved"]:
            raise serializers.ValidationError("You can only rate completed orders.")

        data["order_obj"] = order
        return data

    def create(self, validated_data):
        order = validated_data["order_obj"]

        return Rating.objects.create(
            order=order,
            number=validated_data["number"]
        )


class RatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rating
        fields = ("id", "order", "number")


class RestaurantMenuRequestSerializer(serializers.Serializer):
    restaurant_id = serializers.IntegerField()


class RestaurantSearchSerializer(serializers.Serializer):
    query = serializers.CharField(required=False, allow_blank=True)
    page = serializers.IntegerField(min_value=1, default=1)
    page_size = serializers.IntegerField(min_value=1, max_value=50, default=10)


class MenuItemSyncSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=False)
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(max_length=1024)
    price = serializers.IntegerField()
    expected_duration = serializers.IntegerField()
    is_active = serializers.BooleanField(required=False, default=True)


class CategorySyncSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=False)
    name = serializers.CharField(max_length=255)
    items = MenuItemSyncSerializer(many=True)


class MenuSyncSerializer(serializers.Serializer):
    categories = CategorySyncSerializer(many=True)


class ReorderSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    allow_partial = serializers.BooleanField(default=False)

