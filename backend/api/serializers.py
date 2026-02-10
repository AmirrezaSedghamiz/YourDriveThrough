from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant, Category, MenuItem, Order, OrderItem, Rating, Review
from .exceptions import RoleNotFound


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
    restaurant = serializers.IntegerField()
    number = serializers.IntegerField(min_value=1, max_value=5)
    description = serializers.CharField(
        max_length=1024,
        required=False,
        allow_blank=True
    )

    def validate_restaurant(self, value):
        if not Restaurant.objects.filter(id=value).exists():
            raise serializers.ValidationError("Restaurant does not exist.")
        return value

    def validate(self, data):
        customer = self.context["request"].user.customer
        restaurant_id = data["restaurant"]

        if Rating.objects.filter(
            customer=customer,
            restaurant_id=restaurant_id
        ).exists():
            raise serializers.ValidationError(
                "You have already rated this restaurant."
            )

        return data

    def create(self, validated_data):
        customer = self.context["request"].user.customer
        restaurant = Restaurant.objects.get(id=validated_data["restaurant"])

        rating = Rating.objects.create(
            restaurant=restaurant,
            customer=customer,
            number=validated_data["number"]
        )

        description = validated_data.get("description")
        if description:
            Review.objects.create(
                rating=rating,
                describtion=description
            )

        return rating


class RatingSerializer(serializers.ModelSerializer):
    review = serializers.SerializerMethodField()

    class Meta:
        model = Rating
        fields = ("id", "number", "restaurant", "review")

    def get_review(self, obj):
        if hasattr(obj, "review"):
            return obj.review.describtion
        return None

