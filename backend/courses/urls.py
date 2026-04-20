from django.urls import path

from .views import (
    CertificateListView,
    ClaimCertificateView,
    CourseDetailView,
    CourseListView,
    CourseProgressView,
    DownloadCertificateView,
    EnrollCourseView,
    LeaderboardView,
    LessonDetailView,
    ModuleQuizView,
    SubmitQuizView,
    CompleteLessonView,
    UserProgressView,
)

urlpatterns = [
    path("courses/", CourseListView.as_view(), name="course-list"),
    path("courses/<slug:slug>/", CourseDetailView.as_view(), name="course-detail"),
    path("courses/<slug:slug>/enroll/", EnrollCourseView.as_view(), name="course-enroll"),
    path("lessons/<int:pk>/", LessonDetailView.as_view(), name="lesson-detail"),
    path("lessons/<int:pk>/complete/", CompleteLessonView.as_view(), name="lesson-complete"),
    path("quizzes/<int:module_id>/", ModuleQuizView.as_view(), name="module-quiz"),
    path("quizzes/<int:module_id>/submit/", SubmitQuizView.as_view(), name="quiz-submit"),
    path("progress/", UserProgressView.as_view(), name="user-progress"),
    path("progress/course/<slug:slug>/", CourseProgressView.as_view(), name="course-progress"),
    path("leaderboard/", LeaderboardView.as_view(), name="leaderboard"),
    path("certificates/", CertificateListView.as_view(), name="certificate-list"),
    path("certificates/claim/<slug:slug>/", ClaimCertificateView.as_view(), name="certificate-claim"),
    path(
        "certificates/<str:certificate_id>/download/",
        DownloadCertificateView.as_view(),
        name="certificate-download",
    ),
]

