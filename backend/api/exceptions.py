from rest_framework.exceptions import APIException

class RoleNotFound(APIException):
    status_code = 500
    default_detail = "Server error: user has no role assigned"
    default_code = "no_role"
