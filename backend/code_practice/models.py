from django.conf import settings
from django.db import models


class CodingQuestion(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    problem_statement = models.TextField()
    input_description = models.TextField(blank=True)
    sample_input = models.TextField(blank=True)
    expected_output = models.TextField()
    starter_code = models.TextField(blank=True)
    difficulty = models.CharField(max_length=20, default="beginner")
    order = models.PositiveIntegerField(default=1)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return self.title


class UserCodeSubmission(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="code_submissions",
    )
    question = models.ForeignKey(
        CodingQuestion,
        on_delete=models.CASCADE,
        related_name="submissions",
    )
    submitted_code = models.TextField()
    language = models.CharField(max_length=20, default="python")
    input_used = models.TextField(blank=True)
    actual_output = models.TextField(blank=True)
    expected_output = models.TextField(blank=True)
    stderr_output = models.TextField(blank=True)
    passed = models.BooleanField(default=False)
    execution_time_ms = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.question.title}"
