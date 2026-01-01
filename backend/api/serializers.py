from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant
from .exceptions import RoleNotFound
from django.contrib.auth import get_user_model

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
                restaurant.image
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


class RestaurantProfileSerializer(serializers.ModelSerializer): 
    class Meta: 
        model = Restaurant 
        fields = ["name", "address", "latitude", "longitude", "image"]