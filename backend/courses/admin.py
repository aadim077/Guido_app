from django.contrib import admin

from .models import (
    Certificate,
    Course,
    Lesson,
    Module,
    QuizQuestion,
    UserCourseEnrollment,
    UserLessonProgress,
    UserQuizAttempt,
)


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "difficulty", "order", "is_published")
    list_filter = ("difficulty", "is_published")
    search_fields = ("title", "slug")
    ordering = ("order",)


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = ("title", "course", "order")
    list_filter = ("course",)
    search_fields = ("title", "course__title")
    ordering = ("course__order", "order")


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "module", "order", "duration_minutes")
    list_filter = ("module", "module__course")
    search_fields = ("title", "module__title", "module__course__title")
    ordering = ("module__course__order", "module__order", "order")


@admin.register(QuizQuestion)
class QuizQuestionAdmin(admin.ModelAdmin):
    list_display = ("short_question_text", "module", "correct_option", "order")
    list_filter = ("module",)
    search_fields = ("question_text", "module__title", "module__course__title")
    ordering = ("module__course__order", "module__order", "order")

    @admin.display(description="Question")
    def short_question_text(self, obj: QuizQuestion) -> str:
        text = (obj.question_text or "").strip().replace("\n", " ")
        return text if len(text) <= 70 else f"{text[:67]}..."


@admin.register(UserCourseEnrollment)
class UserCourseEnrollmentAdmin(admin.ModelAdmin):
    list_display = ("user", "course", "enrolled_at", "completed")
    list_filter = ("completed", "course")
    search_fields = ("user__email", "user__username", "course__title", "course__slug")
    ordering = ("-enrolled_at",)


@admin.register(UserLessonProgress)
class UserLessonProgressAdmin(admin.ModelAdmin):
    list_display = ("user", "lesson", "completed")
    list_filter = ("completed", "lesson__module", "lesson__module__course")
    search_fields = ("user__email", "user__username", "lesson__title", "lesson__module__title")
    ordering = ("-completed_at",)


@admin.register(UserQuizAttempt)
class UserQuizAttemptAdmin(admin.ModelAdmin):
    list_display = ("user", "module", "score", "total_questions", "passed")
    list_filter = ("passed", "module__course", "module")
    search_fields = ("user__email", "user__username", "module__title", "module__course__title")
    ordering = ("-attempted_at",)


@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = ("certificate_id", "user", "course", "issued_at")
    list_filter = ("course", "course__difficulty")
    search_fields = ("certificate_id", "user__email", "user__username", "course__title", "course__slug")
    ordering = ("-issued_at",)
