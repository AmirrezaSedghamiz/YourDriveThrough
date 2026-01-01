from django.urls import path
from .views import LoginView
from .views import SignupView
from .views import CompleteRestaurantProfileView
from .views import GetClosestRestaurantsView
from .views import GetRestaurantInfoView, GetRestaurantImageView


urlpatterns = [
    path("login/", LoginView.as_view(), name = "login"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("restaurant/complete_profile/", CompleteRestaurantProfileView.as_view(), name="restaurant_complete_profile"),
    path("restaurant/get_closest/", GetClosestRestaurantsView.as_view(), name="get_closest_restaurants"),
    path("restaurant/info/", GetRestaurantInfoView.as_view(), name="get_restaurant_info"),
    path("restaurant/image/", GetRestaurantImageView.as_view(), name="get_restaurant_image"),
]
