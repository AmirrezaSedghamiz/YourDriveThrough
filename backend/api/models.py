from django.db import models
from django.contrib.auth.models import AbstractBaseUser


class User(AbstractBaseUser):
    phone = models.CharField(max_length=20, unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = []


class Customer(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)


class Restaurant(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    name = models.CharField(max_length=255)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    image = models.ImageField()


class Order(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    start = models.TimeField()
    expected_duration = models.TimeField()
    status = models.CharField(max_length=16)
    total = models.IntegerField()


class Category(models.Model):
    name = models.CharField(max_length=255)


class MenuItem(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    describtion = models.CharField(max_length=1024)
    price = models.IntegerField()
    expected_duration = models.TimeField()
    categories = models.ManyToManyField(Category, related_name="items")
    image = models.ImageField()


class Report(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    describtion = models.CharField(max_length=1024)


class Rating(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    number = models.IntegerField()


class Review(models.Model):
    rating = models.OneToOneField(Rating, on_delete=models.CASCADE)
    describtion = models.CharField(max_length=1024)
