from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .services import validate_version

class AndroidVersionValidateView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        version = request.data.get("version")
        if not version:
            return Response(
                {"detail": "version is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = validate_version("android", version)
        return Response(result)
