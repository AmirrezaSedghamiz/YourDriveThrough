from django.urls import path
from .views import LoginView
from .views import SignupView
from .views import CompleteRestaurantProfileView
from .views import GetClosestRestaurantsView
from .views import GetCategoriesView
from .views import SaveMenuItemView
from .views import OrderCreateView
from .views import ActiveRestaurantOrdersView
from .views import PendingRestaurantOrdersView
from .views import AllRestaurantOrdersView
from .views import RestaurantMenuGroupedView


urlpatterns = [
    path("login/", LoginView.as_view(), name="login"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("restaurant/complete_profile/", CompleteRestaurantProfileView.as_view(), name="restaurant_complete_profile"),
    path("restaurant/get_closest/", GetClosestRestaurantsView.as_view(), name="get_closest_restaurants"),
    path("categories/", GetCategoriesView.as_view(), name="get_categories"),
    path("menu/save/", SaveMenuItemView.as_view(), name="save_menu_item"),
    path("orders/", OrderCreateView.as_view(), name="create_order"),
    path("restaurant/orders/active/", ActiveRestaurantOrdersView.as_view()),
    path("restaurant/orders/pending/", PendingRestaurantOrdersView.as_view()),
    path("restaurant/orders/all/", AllRestaurantOrdersView.as_view()),
    path("restaurants/<int:restaurant_id>/menu/",RestaurantMenuGroupedView.as_view()),
]
