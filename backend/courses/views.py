from __future__ import annotations

import math
from datetime import datetime
from io import BytesIO

from django.db import transaction
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from django.contrib.auth import get_user_model

from .models import Certificate, Course, Lesson, Module, QuizQuestion, UserCourseEnrollment, UserLessonProgress, UserQuizAttempt
from .pdf_generator import generate_certificate_pdf
from .serializers import (
    CertificateSerializer,
    CourseDetailSerializer,
    CourseListSerializer,
    LessonDetailSerializer,
    QuizQuestionSerializer,
    UserProgressSerializer,
    EnrollmentSerializer,
)


def _is_lesson_completed(*, user, lesson: Lesson) -> bool:
    return UserLessonProgress.objects.filter(user=user, lesson=lesson, completed=True).exists()


def _is_module_quiz_passed(*, user, module: Module) -> bool:
    return UserQuizAttempt.objects.filter(user=user, module=module, passed=True).exists()


def _is_lesson_locked(*, user, lesson: Lesson) -> bool:
    if lesson.order == 1 and lesson.module.order == 1:
        return False

    if lesson.order > 1:
        return not UserLessonProgress.objects.filter(
            user=user,
            lesson__module=lesson.module,
            lesson__order=lesson.order - 1,
            completed=True,
        ).exists()

    prev_module = Module.objects.filter(course=lesson.module.course, order=lesson.module.order - 1).only("id").first()
    if not prev_module:
        return False
    return not _is_module_quiz_passed(user=user, module=prev_module)


def _all_lessons_completed_for_module(*, user, module: Module) -> bool:
    lesson_ids = list(module.lessons.values_list("id", flat=True))
    if not lesson_ids:
        return True
    completed_count = UserLessonProgress.objects.filter(user=user, lesson_id__in=lesson_ids, completed=True).count()
    return completed_count == len(lesson_ids)


def _course_completion_status(*, user, course: Course) -> tuple[bool, list[int], list[int]]:
    lesson_ids = list(Lesson.objects.filter(module__course=course).values_list("id", flat=True))
    module_ids = list(course.modules.values_list("id", flat=True))

    completed_lesson_ids = set(
        UserLessonProgress.objects.filter(user=user, lesson_id__in=lesson_ids, completed=True).values_list("lesson_id", flat=True)
    )
    passed_module_ids = set(
        UserQuizAttempt.objects.filter(user=user, module_id__in=module_ids, passed=True).values_list("module_id", flat=True).distinct()
    )

    all_lessons_done = len(completed_lesson_ids) == len(lesson_ids)
    all_quizzes_passed = len(passed_module_ids) == len(module_ids)
    return (all_lessons_done and all_quizzes_passed, sorted(completed_lesson_ids), sorted(passed_module_ids))


def _overall_points_for_user(user) -> int:
    completed_lessons = UserLessonProgress.objects.filter(user=user, completed=True).count()
    passed_modules = (
        UserQuizAttempt.objects.filter(user=user, passed=True)
        .values_list("module_id", flat=True)
        .distinct()
        .count()
    )
    return completed_lessons * 10 + passed_modules * 20


def _overall_progress_percentage_for_user(user) -> int:
    enrolled_course_ids = list(UserCourseEnrollment.objects.filter(user=user).values_list("course_id", flat=True))
    if not enrolled_course_ids:
        return 0
    total_lessons = Lesson.objects.filter(module__course_id__in=enrolled_course_ids).count()
    if total_lessons == 0:
        return 0
    completed_lessons = (
        UserLessonProgress.objects.filter(user=user, completed=True, lesson__module__course_id__in=enrolled_course_ids)
        .values("lesson_id")
        .distinct()
        .count()
    )
    return int(round((completed_lessons / total_lessons) * 100))


class CourseListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = Course.objects.filter(is_published=True).order_by("order")
        data = CourseListSerializer(qs, many=True, context={"request": request}).data
        return Response(data, status=200)


class CourseDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, slug: str):
        course = get_object_or_404(Course.objects.filter(is_published=True), slug=slug)
        data = CourseDetailSerializer(course, context={"request": request}).data
        return Response(data, status=200)


class EnrollCourseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, slug: str):
        course = get_object_or_404(Course.objects.filter(is_published=True), slug=slug)
        enrollment, _ = UserCourseEnrollment.objects.get_or_create(user=request.user, course=course)
        return Response(EnrollmentSerializer(enrollment, context={"request": request}).data, status=200)


class LessonDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk: int):
        lesson = get_object_or_404(Lesson.objects.select_related("module", "module__course"), pk=pk)
        if _is_lesson_locked(user=request.user, lesson=lesson):
            return Response({"error": "Lesson is locked. Complete previous lessons first."}, status=403)
        return Response(LessonDetailSerializer(lesson, context={"request": request}).data, status=200)


class CompleteLessonView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk: int):
        lesson = get_object_or_404(Lesson.objects.select_related("module", "module__course"), pk=pk)
        if _is_lesson_locked(user=request.user, lesson=lesson):
            return Response({"error": "Lesson is locked. Complete previous lessons first."}, status=403)

        progress, created = UserLessonProgress.objects.get_or_create(user=request.user, lesson=lesson)
        if not progress.completed:
            progress.completed = True
            progress.completed_at = timezone.now()
            progress.save(update_fields=["completed", "completed_at"])

        payload = {
            "message": "Lesson marked as completed.",
            "total_points": _overall_points_for_user(request.user),
            "overall_progress_percentage": _overall_progress_percentage_for_user(request.user),
        }
        return Response(payload, status=200)


class ModuleQuizView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, module_id: int):
        module = get_object_or_404(Module.objects.select_related("course"), pk=module_id)
        if not _all_lessons_completed_for_module(user=request.user, module=module):
            return Response({"error": "Complete all lessons in this module before taking the quiz."}, status=403)

        questions = module.quiz_questions.all().order_by("order")
        return Response(QuizQuestionSerializer(questions, many=True).data, status=200)


class SubmitQuizView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, module_id: int):
        module = get_object_or_404(Module.objects.select_related("course"), pk=module_id)
        if not _all_lessons_completed_for_module(user=request.user, module=module):
            return Response({"error": "Complete all lessons in this module before submitting the quiz."}, status=403)

        answers = request.data.get("answers", [])
        if not isinstance(answers, list):
            return Response({"error": "Invalid answers format."}, status=400)

        questions = list(module.quiz_questions.all().order_by("order"))
        total = len(questions)
        if total == 0:
            return Response({"error": "No quiz questions found for this module."}, status=400)

        selected_by_qid: dict[int, str] = {}
        for item in answers:
            try:
                qid = int(item.get("question_id"))
                opt = str(item.get("selected_option")).lower().strip()
            except Exception:
                continue
            if opt in {"a", "b", "c", "d"}:
                selected_by_qid[qid] = opt

        score = 0
        correct_details = []
        for q in questions:
            chosen = selected_by_qid.get(q.id)
            if chosen and chosen == q.correct_option:
                score += 1
            correct_details.append(
                {
                    "question_id": q.id,
                    "correct_option": q.correct_option,
                    "explanation": q.explanation,
                }
            )

        pass_threshold = int(math.ceil(total * 0.7))
        passed = score >= pass_threshold

        attempt = UserQuizAttempt.objects.create(
            user=request.user,
            module=module,
            score=score,
            total_questions=total,
            passed=passed,
        )

        if passed:
            is_complete, _, _ = _course_completion_status(user=request.user, course=module.course)
            if is_complete:
                enrollment = UserCourseEnrollment.objects.filter(user=request.user, course=module.course).first()
                if enrollment and not enrollment.completed:
                    enrollment.completed = True
                    enrollment.completed_at = timezone.now()
                    enrollment.save(update_fields=["completed", "completed_at"])

        return Response(
            {
                "module_id": module.id,
                "score": score,
                "total_questions": total,
                "passed": passed,
                "pass_threshold": pass_threshold,
                "attempted_at": attempt.attempted_at,
                "correct_answers": correct_details,
            },
            status=200,
        )


class UserProgressView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        enrolled_courses_count = UserCourseEnrollment.objects.filter(user=request.user).count()
        completed_courses_count = UserCourseEnrollment.objects.filter(user=request.user, completed=True).count()

        data = UserProgressSerializer(
            {
                "total_points": _overall_points_for_user(request.user),
                "overall_progress_percentage": _overall_progress_percentage_for_user(request.user),
                "enrolled_courses_count": enrolled_courses_count,
                "completed_courses_count": completed_courses_count,
            }
        ).data
        return Response(data, status=200)


class CourseProgressView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, slug: str):
        course = get_object_or_404(Course.objects.filter(is_published=True), slug=slug)
        total_lessons = Lesson.objects.filter(module__course=course).count()
        completed_lesson_ids = list(
            UserLessonProgress.objects.filter(user=request.user, completed=True, lesson__module__course=course)
            .values_list("lesson_id", flat=True)
            .distinct()
        )
        passed_module_ids = list(
            UserQuizAttempt.objects.filter(user=request.user, passed=True, module__course=course)
            .values_list("module_id", flat=True)
            .distinct()
        )
        completed_lessons = len(completed_lesson_ids)
        progress_percentage = int(round((completed_lessons / total_lessons) * 100)) if total_lessons else 0

        is_completed, _, _ = _course_completion_status(user=request.user, course=course)

        return Response(
            {
                "course_id": course.id,
                "course_title": course.title,
                "completed_lessons": completed_lessons,
                "total_lessons": total_lessons,
                "progress_percentage": progress_percentage,
                "is_completed": is_completed,
                "completed_lesson_ids": completed_lesson_ids,
                "passed_module_ids": passed_module_ids,
            },
            status=200,
        )


class CertificateListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        certs = Certificate.objects.filter(user=request.user).select_related("course").order_by("-issued_at")
        return Response(CertificateSerializer(certs, many=True, context={"request": request}).data, status=200)


class ClaimCertificateView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, slug: str):
        course = get_object_or_404(Course.objects.filter(is_published=True), slug=slug)

        existing = Certificate.objects.filter(user=request.user, course=course).first()
        if existing:
            return Response(CertificateSerializer(existing, context={"request": request}).data, status=200)

        is_complete, completed_lesson_ids, passed_module_ids = _course_completion_status(user=request.user, course=course)
        if not is_complete:
            all_lessons = list(Lesson.objects.filter(module__course=course).select_related("module").order_by("module__order", "order"))
            incomplete_lessons = [
                {"id": l.id, "title": l.title, "module": l.module.title}
                for l in all_lessons
                if l.id not in set(completed_lesson_ids)
            ]

            all_modules = list(course.modules.all().order_by("order"))
            incomplete_quizzes = [
                {"id": m.id, "title": m.title}
                for m in all_modules
                if m.id not in set(passed_module_ids)
            ]

            message_parts = []
            if incomplete_quizzes:
                message_parts.append("Quizzes not passed: " + ", ".join(m["title"] for m in incomplete_quizzes))
            if incomplete_lessons:
                message_parts.append("Lessons not completed: " + ", ".join(f"{l['module']} → {l['title']}" for l in incomplete_lessons[:12]))
                if len(incomplete_lessons) > 12:
                    message_parts.append(f"...and {len(incomplete_lessons) - 12} more lessons")

            return Response(
                {
                    "error": "Course is not fully completed. Complete all lessons and pass all module quizzes to claim the certificate.",
                    "details": " | ".join(message_parts) if message_parts else "Incomplete requirements.",
                    "incomplete": {"modules_need_quiz": incomplete_quizzes, "lessons_not_completed": incomplete_lessons},
                },
                status=400,
            )

        cert = Certificate.objects.create(user=request.user, course=course)
        return Response(CertificateSerializer(cert, context={"request": request}).data, status=201)


class DownloadCertificateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, certificate_id: str):
        cert = get_object_or_404(Certificate.objects.select_related("course"), certificate_id=certificate_id)
        if cert.user_id != request.user.id:
            return Response({"error": "You do not have access to this certificate."}, status=403)

        pdf_bytes = generate_certificate_pdf(user=request.user, course=cert.course, certificate_id=cert.certificate_id)
        filename = f"Guido_Certificate_{cert.course.slug}_{cert.certificate_id}.pdf"
        return FileResponse(
            BytesIO(pdf_bytes),
            as_attachment=True,
            filename=filename,
            content_type="application/pdf",
        )


class LeaderboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        User = get_user_model()
        users = User.objects.all()

        entries = []
        for user in users:
            points = _overall_points_for_user(user)
            entries.append({
                "user_id": user.id,
                "username": user.username,
                "points": points,
                "is_current_user": user.id == request.user.id,
            })

        entries.sort(key=lambda e: e["points"], reverse=True)

        for rank, entry in enumerate(entries, start=1):
            entry["rank"] = rank

        return Response(entries, status=200)
