from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import CodingQuestion, UserCodeSubmission
from .serializers import (
    CodingQuestionDetailSerializer,
    CodingQuestionListSerializer,
    RunCodeSerializer,
    SubmitCodeSerializer,
)
from .services import execute_python_code, judge_submission


class CodingQuestionListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        questions = CodingQuestion.objects.filter(is_active=True)
        serializer = CodingQuestionListSerializer(questions, many=True)
        return Response(serializer.data)


class CodingQuestionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            question = CodingQuestion.objects.get(pk=pk, is_active=True)
        except CodingQuestion.DoesNotExist:
            return Response({"error": "Question not found."}, status=404)
        serializer = CodingQuestionDetailSerializer(question)
        return Response(serializer.data)


class RunCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = RunCodeSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"error": serializer.errors}, status=400)

        code = serializer.validated_data["code"]
        custom_input = serializer.validated_data.get("custom_input", "")
        question_id = serializer.validated_data.get("question_id")

        run_input = custom_input
        if not run_input and question_id:
            try:
                question = CodingQuestion.objects.get(id=question_id)
                run_input = question.sample_input
            except CodingQuestion.DoesNotExist:
                pass

        result = execute_python_code(code, user_input=run_input)
        return Response(result)


class SubmitCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SubmitCodeSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"error": serializer.errors}, status=400)

        question_id = serializer.validated_data["question_id"]
        code = serializer.validated_data["code"]

        try:
            question = CodingQuestion.objects.get(id=question_id)
        except CodingQuestion.DoesNotExist:
            return Response({"error": "Question not found."}, status=404)

        # Debug: log exactly which question is being judged
        print("QUESTION:", question.title)
        print("INPUT:", repr(question.sample_input))
        print("EXPECTED:", repr(question.expected_output))

        verdict = judge_submission(
            code=code,
            test_input=question.sample_input,
            expected_output=question.expected_output,
        )

        print("ACTUAL:", repr(verdict["actual_output"]))
        print("PASSED:", verdict["passed"])

        submission = UserCodeSubmission.objects.create(
            user=request.user,
            question=question,
            submitted_code=code,
            input_used=question.sample_input,
            actual_output=verdict["actual_output"],
            expected_output=verdict["expected_output"],
            stderr_output=verdict["stderr_output"],
            passed=verdict["passed"],
            execution_time_ms=verdict["execution_time_ms"],
        )

        return Response(
            {
                "passed": verdict["passed"],
                "actual_output": verdict["actual_output"],
                "expected_output": verdict["expected_output"],
                "stderr_output": verdict["stderr_output"],
                "execution_time_ms": verdict["execution_time_ms"],
                "timed_out": verdict["timed_out"],
                "error_message": verdict["error_message"],
                "submission_id": submission.id,
            }
        )


class SubmissionHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = UserCodeSubmission.objects.filter(
            user=request.user
        ).select_related("question")

        question_id = request.query_params.get("question_id")
        if question_id:
            qs = qs.filter(question_id=question_id)

        qs = qs[:20]

        data = [
            {
                "id": sub.id,
                "question_title": sub.question.title,
                "passed": sub.passed,
                "execution_time_ms": sub.execution_time_ms,
                "created_at": sub.created_at.isoformat(),
            }
            for sub in qs
        ]
        return Response(data)
