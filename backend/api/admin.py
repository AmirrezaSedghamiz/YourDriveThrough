from django.contrib import admin
from .models import (
    User,
    Customer,
    Restaurant,
    Order,
    OrderItem,
    MenuItem,
    Category,
    Rating,
)

admin.site.register(User)
admin.site.register(Customer)
admin.site.register(Restaurant)
admin.site.register(Order)
admin.site.register(OrderItem)
admin.site.register(MenuItem)
admin.site.register(Category)
admin.site.register(Rating)
