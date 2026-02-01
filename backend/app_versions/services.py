from packaging.version import Version
from .models import AppVersion

def validate_version(platform: str, client_version: str):
    client_v = Version(client_version)

    versions = AppVersion.objects.filter(
        platform=platform
    ).order_by("-created_at")

    latest = versions.first()

    for v in versions:
        # If we hit the client's version first → valid
        if Version(v.version) == client_v:
            return {
                "valid": True,
                "latest_version": latest.version,
                "update_available": Version(latest.version) > client_v,
                "force_update": False,
            }

        # If we hit a forced update before client's version → blocked
        if v.force_update:
            return {
                "valid": False,
                "latest_version": latest.version,
                "force_update": True,
                "blocked_by_version": v.version,
            }

    # Client version not found at all (too old or unknown)
    return {
        "valid": False,
        "latest_version": latest.version if latest else None,
        "force_update": True,
        "reason": "version_not_supported",
    }
