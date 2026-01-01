from django.urls import path
from .views import LoginView
from .views import SignupView
from .views import CompleteRestaurantProfileView

urlpatterns = []


urlpatterns = [
    path("login/", LoginView.as_view(), name = "login"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("restaurant/complete_profile/", CompleteRestaurantProfileView.as_view(), name="restaurant_complete_profile"),
]
