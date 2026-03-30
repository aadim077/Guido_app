from __future__ import annotations

from dataclasses import dataclass

from django.db.models import Count, Q
from django.urls import reverse
from rest_framework import serializers

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


def _get_user(context) -> object | None:
    request = context.get("request")
    if not request:
        return None
    user = getattr(request, "user", None)
    if not user or not getattr(user, "is_authenticated", False):
        return None
    return user


@dataclass(frozen=True)
class _LessonGate:
    is_completed: bool
    is_locked: bool


def _lesson_gate(*, user, lesson: Lesson) -> _LessonGate:
    if not user:
        is_first = lesson.order == 1 and lesson.module.order == 1
        return _LessonGate(is_completed=False, is_locked=not is_first)

    completed = UserLessonProgress.objects.filter(user=user, lesson=lesson, completed=True).exists()

    if lesson.order == 1 and lesson.module.order == 1:
        return _LessonGate(is_completed=completed, is_locked=False)

    if lesson.order > 1:
        prev_done = UserLessonProgress.objects.filter(
            user=user,
            lesson__module=lesson.module,
            lesson__order=lesson.order - 1,
            completed=True,
        ).exists()
        return _LessonGate(is_completed=completed, is_locked=not prev_done)

    prev_module = (
        Module.objects.filter(course=lesson.module.course, order=lesson.module.order - 1).only("id").first()
    )
    if not prev_module:
        return _LessonGate(is_completed=completed, is_locked=False)

    prev_quiz_passed = UserQuizAttempt.objects.filter(user=user, module=prev_module, passed=True).exists()
    return _LessonGate(is_completed=completed, is_locked=not prev_quiz_passed)


class LessonListSerializer(serializers.ModelSerializer):
    is_completed = serializers.SerializerMethodField()
    is_locked = serializers.SerializerMethodField()

    class Meta:
        model = Lesson
        fields = ["id", "title", "duration_minutes", "order", "is_completed", "is_locked"]

    def get_is_completed(self, obj: Lesson) -> bool:
        user = _get_user(self.context)
        return _lesson_gate(user=user, lesson=obj).is_completed

    def get_is_locked(self, obj: Lesson) -> bool:
        user = _get_user(self.context)
        return _lesson_gate(user=user, lesson=obj).is_locked


class LessonDetailSerializer(LessonListSerializer):
    class Meta(LessonListSerializer.Meta):
        fields = LessonListSerializer.Meta.fields + ["content", "code_example"]


class ModuleSerializer(serializers.ModelSerializer):
    lessons = LessonListSerializer(many=True, read_only=True)
    quiz_count = serializers.SerializerMethodField()

    class Meta:
        model = Module
        fields = ["id", "title", "order", "description", "lessons", "quiz_count"]

    def get_quiz_count(self, obj: Module) -> int:
        return obj.quiz_questions.count()


class CourseListSerializer(serializers.ModelSerializer):
    total_lessons = serializers.SerializerMethodField()
    total_modules = serializers.SerializerMethodField()
    is_enrolled = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            "id",
            "title",
            "slug",
            "description",
            "difficulty",
            "color_hex",
            "icon",
            "estimated_hours",
            "order",
            "total_lessons",
            "total_modules",
            "is_enrolled",
        ]

    def get_total_modules(self, obj: Course) -> int:
        return obj.modules.count()

    def get_total_lessons(self, obj: Course) -> int:
        return Lesson.objects.filter(module__course=obj).count()

    def get_is_enrolled(self, obj: Course) -> bool:
        user = _get_user(self.context)
        if not user:
            return False
        return UserCourseEnrollment.objects.filter(user=user, course=obj).exists()


class CourseDetailSerializer(CourseListSerializer):
    modules = ModuleSerializer(many=True, read_only=True)

    class Meta(CourseListSerializer.Meta):
        fields = CourseListSerializer.Meta.fields + ["modules"]


class QuizQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizQuestion
        fields = ["id", "question_text", "option_a", "option_b", "option_c", "option_d", "order"]


class QuizAnswerSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    selected_option = serializers.ChoiceField(choices=["a", "b", "c", "d"])


class QuizResultSerializer(serializers.Serializer):
    module_id = serializers.IntegerField()
    answers = QuizAnswerSerializer(many=True)
    score = serializers.IntegerField()
    total_questions = serializers.IntegerField()
    passed = serializers.BooleanField()


class UserProgressSerializer(serializers.Serializer):
    total_points = serializers.IntegerField()
    overall_progress_percentage = serializers.IntegerField()
    enrolled_courses_count = serializers.IntegerField()
    completed_courses_count = serializers.IntegerField()


class CourseProgressSerializer(serializers.Serializer):
    course_id = serializers.IntegerField()
    course_title = serializers.CharField()
    completed_lessons = serializers.IntegerField()
    total_lessons = serializers.IntegerField()
    progress_percentage = serializers.IntegerField()
    is_completed = serializers.BooleanField()


class CertificateSerializer(serializers.ModelSerializer):
    course_title = serializers.CharField(source="course.title", read_only=True)
    course_difficulty = serializers.CharField(source="course.difficulty", read_only=True)
    download_url = serializers.SerializerMethodField()

    class Meta:
        model = Certificate
        fields = ["id", "certificate_id", "course_title", "course_difficulty", "issued_at", "download_url"]

    def get_download_url(self, obj: Certificate) -> str:
        request = self.context.get("request")
        path = reverse("certificate-download", kwargs={"certificate_id": obj.certificate_id})
        return request.build_absolute_uri(path) if request else path


class BasicCourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = ["id", "title", "slug", "difficulty", "color_hex", "icon", "estimated_hours", "order"]


class EnrollmentSerializer(serializers.ModelSerializer):
    course = BasicCourseSerializer(read_only=True)

    class Meta:
        model = UserCourseEnrollment
        fields = ["id", "course", "enrolled_at", "completed"]

