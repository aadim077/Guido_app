from django.core.management.base import BaseCommand

from code_practice.models import CodingQuestion


QUESTIONS = [
    {
        "title": "Print Hello Guido",
        "slug": "print-hello-guido",
        "problem_statement": "Write a Python program that prints 'Hello Guido'.",
        "input_description": "No input required.",
        "sample_input": "",
        "expected_output": "Hello Guido",
        "starter_code": 'print("Hello Guido")',
        "difficulty": "beginner",
        "order": 1,
    },
    {
        "title": "Sum of Two Numbers",
        "slug": "sum-of-two-numbers",
        "problem_statement": "Read two integers from standard input and print their sum.",
        "input_description": "Two integers separated by a space.",
        "sample_input": "3 5",
        "expected_output": "8",
        "starter_code": "a, b = map(int, input().split())\nprint(a + b)",
        "difficulty": "beginner",
        "order": 2,
    },
    {
        "title": "Even or Odd",
        "slug": "even-or-odd",
        "problem_statement": (
            "Read an integer and print 'Even' if it is even, "
            "otherwise print 'Odd'."
        ),
        "input_description": "One integer.",
        "sample_input": "7",
        "expected_output": "Odd",
        "starter_code": (
            "n = int(input())\n"
            "if n % 2 == 0:\n"
            '    print("Even")\n'
            "else:\n"
            '    print("Odd")'
        ),
        "difficulty": "beginner",
        "order": 3,
    },
    {
        "title": "Maximum of Three Numbers",
        "slug": "maximum-of-three-numbers",
        "problem_statement": "Read three integers and print the largest one.",
        "input_description": "Three integers separated by a space.",
        "sample_input": "4 9 2",
        "expected_output": "9",
        "starter_code": "a, b, c = map(int, input().split())\nprint(max(a, b, c))",
        "difficulty": "beginner",
        "order": 4,
    },
    {
        "title": "Reverse a String",
        "slug": "reverse-a-string",
        "problem_statement": "Read a string and print it reversed.",
        "input_description": "A single string.",
        "sample_input": "python",
        "expected_output": "nohtyp",
        "starter_code": "text = input()\nprint(text[::-1])",
        "difficulty": "beginner",
        "order": 5,
    },
]


class Command(BaseCommand):
    help = "Seed the five coding practice questions."

    def handle(self, *args, **options):
        for q_data in QUESTIONS:
            obj, created = CodingQuestion.objects.update_or_create(
                slug=q_data["slug"],
                defaults=q_data,
            )
            status = "Created" if created else "Updated"
            self.stdout.write(f"  {status}: {obj.title}")

        self.stdout.write(self.style.SUCCESS("Seeded 5 coding questions."))
