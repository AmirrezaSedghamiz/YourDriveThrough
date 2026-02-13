from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, CustomerReport, Restaurant, Category, MenuItem, Order, OrderItem, Rating, RestaurantReport
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

import requests
from django.conf import settings
from django.utils import timezone
from rest_framework import serializers
from django.db import transaction

class OrderItemCreateSerializer(serializers.Serializer):
    menu_item = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)
    special = serializers.CharField(required=False, allow_blank=True)


class OrderCreateSerializer(serializers.Serializer):
    restaurant = serializers.IntegerField()
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    items = OrderItemCreateSerializer(many=True)

    def validate(self, data):
        request = self.context["request"]

        if not hasattr(request.user, "customer"):
            raise serializers.ValidationError("Only customers can create orders.")

        items = data["items"]
        restaurant_id = data["restaurant"]

        if not items:
            raise serializers.ValidationError("Order must contain at least one item.")

        menu_items = MenuItem.objects.filter(
            id__in=[i["menu_item"] for i in items],
            is_active=True,
            category__restaurant_id=restaurant_id,
        ).select_related("category")

        if menu_items.count() != len(items):
            raise serializers.ValidationError(
                "All items must belong to the restaurant and be active."
            )

        self._menu_items_map = {m.id: m for m in menu_items}
        return data

    def create(self, validated_data):
        request = self.context["request"]
        customer = request.user.customer

        restaurant_id = validated_data["restaurant"]
        lat = validated_data["latitude"]
        lon = validated_data["longitude"]
        items_data = validated_data["items"]

        restaurant = Restaurant.objects.get(id=restaurant_id)

        total = 0
        max_duration = 0

        for item in items_data:
            menu_item = self._menu_items_map[item["menu_item"]]
            qty = item["quantity"]

            total += menu_item.price * qty

            if menu_item.expected_duration > max_duration:
                max_duration = menu_item.expected_duration

        expected_arrival_time = 0
        if (
            restaurant.latitude is not None
            and restaurant.longitude is not None
            and restaurant.latitude >= 0
            and restaurant.longitude >= 0
            and lat >= 0
            and lon >= 0
        ):
            origins = f"{lat:.6f},{lon:.6f}"
            destinations = f"{float(restaurant.latitude):.6f},{float(restaurant.longitude):.6f}"

            url = (
                "https://api.neshan.org/v1/distance-matrix"
                f"?type=car&origins={origins}&destinations={destinations}"
            )

            headers = {"Api-Key": settings.NESHAN_API_KEY}

            try:
                response = requests.get(url, headers=headers, timeout=5)
                response.raise_for_status()
                data = response.json()

                elements = data.get("rows", [{}])[0].get("elements", [])
                if elements:
                    travel_seconds = elements[0].get("duration", {}).get("value", 0)
                    expected_arrival_time = int(travel_seconds)
            except requests.RequestException:
                expected_arrival_time = 0

        with transaction.atomic():
            order = Order.objects.create(
                customer=customer,
                restaurant=restaurant,
                start=timezone.now(),
                expected_duration=max_duration,
                expected_arrival_time=expected_arrival_time,
                status="pending",
                total=total,
            )

            order_items = []
            for item in items_data:
                menu_item = self._menu_items_map[item["menu_item"]]
                order_items.append(
                    OrderItem(
                        order=order,
                        item=menu_item,
                        quantity=item["quantity"],
                        special=item.get("special", ""),
                    )
                )

            OrderItem.objects.bulk_create(order_items)
        return self.data


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
    restaurant = serializers.IntegerField(source = "restaurant.id",read_only=True)
    customer = serializers.IntegerField(source = "customer.id",read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "restaurant",
            "customer",
            "status",
            "total",
            "start",
            "expected_duration",
            "expected_arrival_time",
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


class CustomerUpdateSerializer(serializers.Serializer):
    phone = serializers.CharField(required=False, max_length=20)
    image = serializers.ImageField(required=False, allow_null=True)

    def validate_phone(self, value):
        user = self.context["request"].user
        if User.objects.exclude(id=user.id).filter(phone=value).exists():
            raise serializers.ValidationError("This phone is already in use.")
        return value



class CustomerReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerReport
        fields = ["id", "restaurant", "description", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_restaurant(self, value):
        if not Restaurant.objects.filter(id=value.id).exists():
            raise serializers.ValidationError("Restaurant does not exist.")
        return value


class RestaurantReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantReport
        fields = ["id", "customer", "description", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_customer(self, value):
        if not Customer.objects.filter(id=value.id).exists():
            raise serializers.ValidationError("Customer does not exist.")
        return value
