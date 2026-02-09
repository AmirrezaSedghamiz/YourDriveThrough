# api/authentication.py
from __future__ import annotations

from django.contrib.auth.backends import BaseBackend
from django.contrib.auth import get_user_model

User = get_user_model()


class PhoneBackend(BaseBackend):
    """
    Authenticate using exact match on User.phone.
    """

    def authenticate(self, request, username=None, password=None, phone=None, **kwargs):
        phone_value = phone or username
        if not phone_value or not password:
            return None

        try:
            user = User.objects.get(phone=phone_value)
        except User.DoesNotExist:
            return None

        # Optional: block inactive users
        if hasattr(user, "is_active") and not user.is_active:
            return None

        # This only works if passwords were set via user.set_password(...)
        if user.check_password(password):
            return user

        return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None
