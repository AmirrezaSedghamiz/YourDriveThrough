from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant
from .exceptions import RoleNotFound

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
