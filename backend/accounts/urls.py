from django.urls import path

from .views import AdminDashboardView, LoginView, SignupView, UserProfileView

urlpatterns = [
    path("auth/signup/", SignupView.as_view(), name="signup"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/profile/", UserProfileView.as_view(), name="profile"),
    path("admin/dashboard/", AdminDashboardView.as_view(), name="admin-dashboard"),
]

