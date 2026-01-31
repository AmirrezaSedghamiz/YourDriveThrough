from django.urls import path
from .views import AndroidVersionValidateView

urlpatterns = [
    path("android/validate", AndroidVersionValidateView.as_view()),
]