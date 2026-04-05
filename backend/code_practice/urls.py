from django.urls import path

from . import views

urlpatterns = [
    path("code/questions/", views.CodingQuestionListView.as_view(), name="coding-question-list"),
    path("code/questions/<int:pk>/", views.CodingQuestionDetailView.as_view(), name="coding-question-detail"),
    path("code/run/", views.RunCodeView.as_view(), name="code-run"),
    path("code/submit/", views.SubmitCodeView.as_view(), name="code-submit"),
    path("code/submissions/", views.SubmissionHistoryView.as_view(), name="code-submissions"),
]
