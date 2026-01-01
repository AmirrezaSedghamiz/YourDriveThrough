from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import LoginSerializer
from .serializers import SignupSerializer
from .serializers import RestaurantProfileSerializer
from .serializers import ClosestRestaurantsSerializer
from .models import Restaurant
from .utils import haversine

class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_403_FORBIDDEN)


class SignupView(APIView):
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            result = serializer.save()
            return Response(result, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CompleteRestaurantProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            restaurant = Restaurant.objects.get(user=request.user)
        except Restaurant.DoesNotExist:
            return Response({"error": "Access violation: not a restaurant"}, status=status.HTTP_403_FORBIDDEN)

        serializer = RestaurantProfileSerializer(restaurant, data=request.data)
        if serializer.is_valid():
            serializer.save()
            profile_complete = all([
                restaurant.name,
                restaurant.address,
                restaurant.latitude,
                restaurant.longitude,
                restaurant.image
            ])
            return Response({
                "message": "Profile updated successfully",
                "profile_complete": profile_complete
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
            distances.append((r.id, dist))

        # Sort by distance
        distances.sort(key=lambda x: x[1])

        # Apply pagination
        selected = distances[index:index+count]
        ids = [r[0] for r in selected]

        return Response({"restaurant_ids": ids}, status=status.HTTP_200_OK)
