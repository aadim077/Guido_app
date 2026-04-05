from rest_framework import serializers

from .models import CodingQuestion


class CodingQuestionListSerializer(serializers.ModelSerializer):
    class Meta:
        model = CodingQuestion
        fields = ["id", "title", "slug", "difficulty", "order"]


class CodingQuestionDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = CodingQuestion
        fields = [
            "id",
            "title",
            "slug",
            "problem_statement",
            "input_description",
            "sample_input",
            "expected_output",
            "starter_code",
            "difficulty",
            "order",
        ]


class RunCodeSerializer(serializers.Serializer):
    question_id = serializers.IntegerField(required=False)
    code = serializers.CharField()
    custom_input = serializers.CharField(required=False, default="")

    def validate_code(self, value):
        if not value.strip():
            raise serializers.ValidationError("Code cannot be empty.")
        return value


class SubmitCodeSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    code = serializers.CharField()

    def validate_code(self, value):
        if not value.strip():
            raise serializers.ValidationError("Code cannot be empty.")
        return value

    def validate_question_id(self, value):
        if not CodingQuestion.objects.filter(id=value, is_active=True).exists():
            raise serializers.ValidationError("Question not found.")
        return value


class RunCodeResponseSerializer(serializers.Serializer):
    stdout = serializers.CharField()
    stderr = serializers.CharField()
    timed_out = serializers.BooleanField()
    execution_time_ms = serializers.IntegerField()
    success = serializers.BooleanField()


class SubmitCodeResponseSerializer(serializers.Serializer):
    passed = serializers.BooleanField()
    actual_output = serializers.CharField()
    expected_output = serializers.CharField()
    stderr_output = serializers.CharField()
    execution_time_ms = serializers.IntegerField()
    timed_out = serializers.BooleanField()
    submission_id = serializers.IntegerField()


class SubmissionHistorySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    question_title = serializers.CharField()
    passed = serializers.BooleanField()
    execution_time_ms = serializers.IntegerField()
    created_at = serializers.DateTimeField()
