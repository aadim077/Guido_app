from django.contrib import admin

from .models import CodingQuestion, UserCodeSubmission


@admin.register(CodingQuestion)
class CodingQuestionAdmin(admin.ModelAdmin):
    list_display = ("title", "difficulty", "order", "is_active")
    list_filter = ("difficulty", "is_active")
    search_fields = ("title", "slug")


@admin.register(UserCodeSubmission)
class UserCodeSubmissionAdmin(admin.ModelAdmin):
    list_display = ("user", "question", "passed", "execution_time_ms", "created_at")
    list_filter = ("passed", "language", "question")
    search_fields = ("user__email", "question__title")
