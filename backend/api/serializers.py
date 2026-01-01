from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Customer, Restaurant

class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=["customer", "restaurant"])

    def validate(self, data):
        user = authenticate(username=data["phone"], password=data["password"])
        if not user:
            raise serializers.ValidationError({"error": "Invalid credentials"})

        role = data["role"]

        if role == "restaurant":
            try:
                restaurant = Restaurant.objects.get(user=user)
            except Restaurant.DoesNotExist:
                raise serializers.ValidationError({"error": "Access violation: this user is not a restaurant"})

            # Profile completeness check
            profile_complete = all([
                restaurant.name,
                restaurant.address,
                restaurant.latitude,
                restaurant.longitude,
                restaurant.image
            ])

        elif role == "customer":
            if not Customer.objects.filter(user=user).exists():
                raise serializers.ValidationError({"error": "Access violation: this user is not a customer"})
            profile_complete = None  # not relevant for customers

        # Issue tokens
        refresh = RefreshToken.for_user(user)
        response = {
            "access_token": str(refresh.access_token),
            "refresh_token": str(refresh),
        }
        if role == "restaurant":
            response["profile_complete"] = profile_complete

        return response
