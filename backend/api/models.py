from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError("Phone is required")

        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        return self.create_user(phone, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    phone = models.CharField(max_length=20, unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = []


class Customer(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    image = models.ImageField(default=None, null=True, blank=True)


class Restaurant(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    name = models.CharField(max_length=255,null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    latitude = models.DecimalField(max_digits=15, decimal_places=12, null=True, blank=True)
    longitude = models.DecimalField(max_digits=15, decimal_places=12, null=True, blank=True)
    image = models.ImageField(null=True, blank=True)

    is_open = models.BooleanField(default=False)



class Order(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)

    start = models.DateTimeField()
    expected_duration = models.IntegerField()

    expected_arrival_time = models.IntegerField(default=0)

    status = models.CharField(max_length=16)
    total = models.IntegerField()



class Category(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)


class MenuItem(models.Model):
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    description = models.CharField(max_length=1024)
    price = models.IntegerField()
    expected_duration = models.IntegerField()
    image = models.ImageField(null=True, blank=True)
    is_active = models.BooleanField(default=True)



class CustomerReport(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name="reports")
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name="reported_by_customers")
    description = models.CharField(max_length=1024)
    created_at = models.DateTimeField(auto_now_add=True)


class RestaurantReport(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name="reports")
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name="reported_by_restaurants")
    description = models.CharField(max_length=1024)
    created_at = models.DateTimeField(auto_now_add=True)


class Rating(models.Model):
    order = models.OneToOneField(Order, on_delete=models.CASCADE)
    number = models.IntegerField()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["order"],
                name="unique_rating_per_order"
            )
        ]


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    item = models.ForeignKey(MenuItem, on_delete=models.CASCADE)
    quantity = models.IntegerField()
    special = models.CharField(max_length=1024,null=True, blank=True)