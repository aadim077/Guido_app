import uuid

from django.conf import settings
from django.db import models


class Course(models.Model):
    class Difficulty(models.TextChoices):
        BEGINNER = "beginner", "Beginner"
        INTERMEDIATE = "intermediate", "Intermediate"
        ADVANCED = "advanced", "Advanced"

    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField()
    difficulty = models.CharField(max_length=20, choices=Difficulty.choices)
    color_hex = models.CharField(max_length=7)
    icon = models.CharField(max_length=50)
    estimated_hours = models.IntegerField()
    order = models.IntegerField()
    is_published = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]

    def __str__(self) -> str:
        return self.title


class Module(models.Model):
    course = models.ForeignKey(Course, related_name="modules", on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    order = models.IntegerField()
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]
        unique_together = [("course", "order")]

    def __str__(self) -> str:
        return f"{self.course.title} - {self.title}"


class Lesson(models.Model):
    module = models.ForeignKey(Module, related_name="lessons", on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    content = models.TextField()
    code_example = models.TextField(blank=True, null=True)
    duration_minutes = models.IntegerField()
    order = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]
        unique_together = [("module", "order")]

    def __str__(self) -> str:
        return f"{self.module.title} - {self.title}"


class QuizQuestion(models.Model):
    class Option(models.TextChoices):
        A = "a", "A"
        B = "b", "B"
        C = "c", "C"
        D = "d", "D"

    module = models.ForeignKey(Module, related_name="quiz_questions", on_delete=models.CASCADE)
    question_text = models.TextField()
    option_a = models.CharField(max_length=255)
    option_b = models.CharField(max_length=255)
    option_c = models.CharField(max_length=255)
    option_d = models.CharField(max_length=255)
    correct_option = models.CharField(max_length=1, choices=Option.choices)
    explanation = models.TextField(blank=True)
    order = models.IntegerField()

    class Meta:
        ordering = ["order"]

    def __str__(self) -> str:
        text = self.question_text.strip().replace("\n", " ")
        return text if len(text) <= 60 else f"{text[:57]}..."


class UserCourseEnrollment(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="enrollments", on_delete=models.CASCADE)
    course = models.ForeignKey(Course, related_name="enrollments", on_delete=models.CASCADE)
    enrolled_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = [("user", "course")]

    def __str__(self) -> str:
        return f"{self.user} enrolled in {self.course.title}"


class UserLessonProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="lesson_progress", on_delete=models.CASCADE)
    lesson = models.ForeignKey(Lesson, related_name="user_progress", on_delete=models.CASCADE)
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = [("user", "lesson")]

    def __str__(self) -> str:
        return f"{self.user} completed {self.lesson.title}"


class UserQuizAttempt(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="quiz_attempts", on_delete=models.CASCADE)
    module = models.ForeignKey(Module, related_name="quiz_attempts", on_delete=models.CASCADE)
    score = models.IntegerField()
    total_questions = models.IntegerField()
    passed = models.BooleanField(default=False)
    attempted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-attempted_at"]

    def __str__(self) -> str:
        return f"{self.user} quiz for {self.module.title} {self.score}/{self.total_questions}"


class Certificate(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="certificates", on_delete=models.CASCADE)
    course = models.ForeignKey(Course, related_name="certificates", on_delete=models.CASCADE)
    certificate_id = models.CharField(max_length=50, unique=True, blank=True)
    issued_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("user", "course")]

    def __str__(self) -> str:
        return f"Certificate for {self.user} in {self.course.title}"

    def save(self, *args, **kwargs):
        if not self.certificate_id:
            self.certificate_id = uuid.uuid4().hex[:12].upper()
        super().save(*args, **kwargs)
