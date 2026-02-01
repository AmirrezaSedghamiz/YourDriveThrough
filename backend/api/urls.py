from django.urls import path
from .views import LoginView
from .views import SignupView
from .views import CompleteRestaurantProfileView
from .views import GetClosestRestaurantsView
from .views import GetCategoriesView
from .views import SaveMenuItemView


urlpatterns = [
    path("login/", LoginView.as_view(), name="login"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("restaurant/complete_profile/", CompleteRestaurantProfileView.as_view(), name="restaurant_complete_profile"),
    path("restaurant/get_closest/", GetClosestRestaurantsView.as_view(), name="get_closest_restaurants"),
    path("categories/", GetCategoriesView.as_view(), name="get_categories"),
    path("menu/save/", SaveMenuItemView.as_view(), name="save_menu_item"),
]
