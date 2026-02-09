from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant, Category, MenuItem, Order, OrderItem
from .exceptions import RoleNotFound
from django.contrib.auth import login


User = get_user_model()

class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        request = self.context["request"]

        user = authenticate(
            request=request,
            phone=data["phone"],
            password=data["password"],
        )

        if not user:
            raise serializers.ValidationError({"error": "Invalid credentials"})

        login(request, user)

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
                restaurant.image,
            ])
        else:
            raise RoleNotFound()

        response = {
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
        request = self.context["request"]

        role = validated_data["role"]
        phone = validated_data["phone"]
        password = validated_data["password"]

        user = User.objects.create(phone=phone)
        user.set_password(password)
        user.save()

        if role == "customer":
            Customer.objects.create(user=user)
        else:
            Restaurant.objects.create(user=user)

        login(request, user)

        return {
            "role": role,
        }


class RestaurantSerializer(serializers.ModelSerializer):
    profile_complete = serializers.SerializerMethodField()

    class Meta:
        model = Restaurant
        fields = ["id", "name", "address", "latitude", "longitude", "image", "profile_complete"]

    def get_profile_complete(self, obj):
        return all([
            bool(obj.name),
            bool(obj.address),
            obj.latitude is not None,
            obj.longitude is not None,
            bool(obj.image)
        ])


class ClosestRestaurantsSerializer(serializers.Serializer):
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    index = serializers.IntegerField(min_value=0)
    count = serializers.IntegerField(min_value=1, max_value=50)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name"]


class MenuItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenuItem
        fields = [
            "id",
            "restaurant",
            "name",
            "description",
            "price",
            "expected_duration",
            "categories",
            "image",
        ]


class OrderItemCreateSerializer(serializers.Serializer):
    menu_item = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)
    special = serializers.CharField(required=False, allow_blank=True)


class OrderCreateSerializer(serializers.ModelSerializer):
    items = OrderItemCreateSerializer(many=True)

    class Meta:
        model = Order
        fields = ("restaurant", "items")

    def validate(self, data):
        items = data["items"]
        restaurant = data["restaurant"]

        menu_items = MenuItem.objects.filter(
            id__in=[i["menu_item"] for i in items],
            is_active=True,
            restaurant=restaurant,
        )

        if menu_items.count() != len(items):
            raise serializers.ValidationError(
                "All items must belong to the restaurant and be active."
            )

        return data

    def create(self, validated_data):
        items_data = validated_data.pop("items")
        restaurant = validated_data["restaurant"]

        total = 0
        max_duration = None

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

            if not max_duration or menu_item.expected_duration > max_duration:
                max_duration = menu_item.expected_duration

        order = Order.objects.create(
            restaurant=restaurant,
            expected_duration=max_duration,
            total=total,
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


class OrderItemReadSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="item.name", read_only=True)

    class Meta:
        model = OrderItem
        fields = ("id", "item_name", "quantity", "special")


class OrderReadSerializer(serializers.ModelSerializer):
    items = OrderItemReadSerializer(
        source="orderitem_set", many=True, read_only=True
    )

    customer_id = serializers.IntegerField(source="customer.id", read_only=True)

    class Meta:
        model = Order
        fields = (
            "id",
            "customer_id",
            "status",
            "created_at",
            "expected_duration",
            "total",
            "items",
        )
