from django.contrib.auth import get_user_model
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .permissions import IsAdminRole
from .serializers import LoginSerializer, SignupSerializer, UserSerializer

User = get_user_model()


class SignupView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if not serializer.is_valid():
            # keeping it simple: surface a single error string
            detail = serializer.errors
            if isinstance(detail, dict) and "error" in detail:
                return Response({"error": detail["error"][0] if isinstance(detail["error"], list) else detail["error"]}, status=400)
            return Response({"error": "Invalid signup data"}, status=400)

        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "tokens": {"access": str(refresh.access_token), "refresh": str(refresh)},
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "role": user.role,
                    "phone": user.phone,
                },
            },
            status=201,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            detail = serializer.errors
            if isinstance(detail, dict) and "error" in detail:
                return Response({"error": detail["error"][0] if isinstance(detail["error"], list) else detail["error"]}, status=400)
            return Response({"error": "Invalid credentials"}, status=400)

        return Response(serializer.validated_data, status=200)


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data, status=200)


class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated, IsAdminRole]

    def get(self, request):
        total_users = User.objects.count()
        recent_users = User.objects.order_by("-created_at")[:5]
        recent_payload = [
            {
                "id": u.id,
                "email": u.email,
                "username": u.username,
                "role": u.role,
                "phone": u.phone,
            }
            for u in recent_users
        ]

        return Response(
            {
                "message": f"Welcome back, {request.user.username}",
                "stats": {
                    "total_users": total_users,
                    "recent_users": recent_payload,
                },
            },
            status=200,
        )
