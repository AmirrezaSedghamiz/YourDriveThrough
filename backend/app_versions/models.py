from django.db import models

class Platform(models.TextChoices):
    ANDROID = "android", "Android"
    IOS = "ios", "iOS"

class AppVersion(models.Model):
    platform = models.CharField(
        max_length=20,
        choices=Platform.choices,
        db_index=True,
    )

    version = models.CharField(max_length=20)
    force_update = models.BooleanField(default=False)

    release_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("platform", "version")
        ordering = ["-created_at"]  # newest first

    def __str__(self):
        return f"{self.platform} {self.version}"
