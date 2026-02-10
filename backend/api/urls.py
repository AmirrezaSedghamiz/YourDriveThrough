from django.urls import path
from .views import LoginView, MeView
from .views import SignupView
from .views import RestaurantMeUpdateView
from .views import GetClosestRestaurantsView
from .views import GetCategoriesView
from .views import SaveMenuItemView
from .views import OrderCreateView
from .views import ActiveRestaurantOrdersView
from .views import PendingRestaurantOrdersView
from .views import AllRestaurantOrdersView
from .views import RestaurantMenuGroupedView
from .views import MyOrdersView


urlpatterns = [
    path("login/", LoginView.as_view(), name="login"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("restaurant/get_closest/", GetClosestRestaurantsView.as_view(), name="get_closest_restaurants"),
    path("categories/", GetCategoriesView.as_view(), name="get_categories"),
    path("menu/save/", SaveMenuItemView.as_view(), name="save_menu_item"),
    path("orders/", OrderCreateView.as_view(), name="create_order"),
    path("restaurants/<int:restaurant_id>/menu/",RestaurantMenuGroupedView.as_view()),

    # New endpoint for handling current user.
    path("me/", MeView.as_view(), name="me"),
    path("me/restaurant/", RestaurantMeUpdateView.as_view(), name="restaurant_me_update"),
    path("me/orders/", MyOrdersView.as_view(), name="my_orders"),

    # Deprecated endpoint for handling current user (to be removed in the future).
    path("restaurant/complete_profile/", RestaurantMeUpdateView.as_view(), name="restaurant_complete_profile"),
    path("restaurant/orders/active/", ActiveRestaurantOrdersView.as_view()),
    path("restaurant/orders/pending/", PendingRestaurantOrdersView.as_view()),
    path("restaurant/orders/all/", AllRestaurantOrdersView.as_view()),
]

