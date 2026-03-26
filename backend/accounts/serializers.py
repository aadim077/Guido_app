from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "username", "role", "phone", "created_at"]
        read_only_fields = ["id", "email", "username", "role", "created_at"]


class SignupSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=15, allow_null=True, allow_blank=True, required=False)
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True, min_length=6)

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError("Email already registered")
        return email

    def validate(self, attrs):
        if attrs.get("password") != attrs.get("password_confirm"):
            raise serializers.ValidationError({"error": "Passwords do not match"})
        return attrs

    def create(self, validated_data):
        validated_data.pop("password_confirm", None)
        email = validated_data.get("email", "").strip().lower()
        username = validated_data.get("username")
        phone = validated_data.get("phone") or None

        user = User.objects.create_user(
            username=username,
            email=email,
            password=validated_data.get("password"),
        )
        user.phone = phone
        user.role = "user"  # signups are always regular users
        user.save(update_fields=["phone", "role"])
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get("email", "").strip().lower()
        password = attrs.get("password")

        user = authenticate(username=email, password=password)
        if not user:
            raise serializers.ValidationError({"error": "Invalid credentials"})

        refresh = RefreshToken.for_user(user)

        return {
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            "user": {
                "id": user.id,
                "email": user.email,
                "username": user.username,
                "role": user.role,
                "phone": user.phone,
            },
        }

