from __future__ import annotations

from dataclasses import dataclass

from django.core.management.base import BaseCommand
from django.db import transaction

from courses.models import Course, Lesson, Module, QuizQuestion


@dataclass(frozen=True)
class LessonSeed:
    title: str
    duration_minutes: int
    order: int
    content: str
    code_example: str | None = None


@dataclass(frozen=True)
class QuizSeed:
    order: int
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str
    explanation: str


@dataclass(frozen=True)
class ModuleSeed:
    title: str
    order: int
    description: str
    lessons: list[LessonSeed]
    quiz: list[QuizSeed]


@dataclass(frozen=True)
class CourseSeed:
    title: str
    slug: str
    description: str
    difficulty: str
    color_hex: str
    icon: str
    estimated_hours: int
    order: int
    is_published: bool
    modules: list[ModuleSeed]


def _upsert_course(seed: CourseSeed) -> Course:
    course, _ = Course.objects.update_or_create(
        slug=seed.slug,
        defaults={
            "title": seed.title,
            "description": seed.description,
            "difficulty": seed.difficulty,
            "color_hex": seed.color_hex,
            "icon": seed.icon,
            "estimated_hours": seed.estimated_hours,
            "order": seed.order,
            "is_published": seed.is_published,
        },
    )
    return course


def _upsert_module(course: Course, seed: ModuleSeed) -> Module:
    module, _ = Module.objects.update_or_create(
        course=course,
        order=seed.order,
        defaults={
            "title": seed.title,
            "description": seed.description,
        },
    )
    return module


def _upsert_lesson(module: Module, seed: LessonSeed) -> Lesson:
    lesson, _ = Lesson.objects.update_or_create(
        module=module,
        order=seed.order,
        defaults={
            "title": seed.title,
            "content": seed.content,
            "code_example": seed.code_example,
            "duration_minutes": seed.duration_minutes,
        },
    )
    return lesson


def _upsert_quiz_question(module: Module, seed: QuizSeed) -> QuizQuestion:
    question, _ = QuizQuestion.objects.update_or_create(
        module=module,
        order=seed.order,
        defaults={
            "question_text": seed.question_text,
            "option_a": seed.option_a,
            "option_b": seed.option_b,
            "option_c": seed.option_c,
            "option_d": seed.option_d,
            "correct_option": seed.correct_option,
            "explanation": seed.explanation,
        },
    )
    return question


def _seed_data() -> list[CourseSeed]:
    return [
        CourseSeed(
            title="Python Fundamentals",
            slug="python-fundamentals",
            description=(
                "Start from zero and build a strong Python foundation: syntax, variables, conditions, loops, and core data structures. "
                "You’ll finish with mini-projects that tie everything together."
            ),
            difficulty="beginner",
            color_hex="#4CAF50",
            icon="python",
            estimated_hours=8,
            order=1,
            is_published=True,
            modules=[
                ModuleSeed(
                    title="Getting Started",
                    order=1,
                    description="Meet Python, set it up, and write your first programs.",
                    lessons=[
                        LessonSeed(
                            title="What is Python?",
                            duration_minutes=10,
                            order=1,
                            content=(
                                "Python is a high-level, interpreted programming language created by Guido van Rossum. "
                                "It was designed with readability in mind, so code feels close to plain English.\n\n"
                                "Because Python is interpreted, you can run code quickly without a separate compile step. "
                                "That makes it great for learning and for rapid development.\n\n"
                                "Where Python is used:\n"
                                "- Web development (Django, Flask)\n"
                                "- Data science (pandas, NumPy)\n"
                                "- AI/ML (PyTorch, TensorFlow)\n"
                                "- Automation and scripting\n\n"
                                "Your first Python program is often a simple print statement:\n\n"
                                "```python\n"
                                "print(\"Hello, World!\")\n"
                                "```\n\n"
                                "Key takeaway: Python is popular because it’s readable, versatile, and has a huge ecosystem."
                            ),
                            code_example="print(\"Hello, World!\")",
                        ),
                        LessonSeed(
                            title="Installation and Setup",
                            duration_minutes=15,
                            order=2,
                            content=(
                                "To install Python, download it from python.org and run the installer.\n\n"
                                "On Windows, make sure you check **“Add Python to PATH”** during installation.\n\n"
                                "After installing, verify it in a terminal:\n\n"
                                "```bash\n"
                                "python --version\n"
                                "```\n\n"
                                "You can write Python in:\n"
                                "- IDLE (simple editor included with Python)\n"
                                "- VS Code (popular and beginner-friendly)\n\n"
                                "To run a Python file from the terminal:\n"
                                "1) Create a file like `hello.py`\n"
                                "2) Put this code inside:\n\n"
                                "```python\n"
                                "print(\"Hello from a file!\")\n"
                                "```\n\n"
                                "3) Run it:\n\n"
                                "```bash\n"
                                "python hello.py\n"
                                "```\n\n"
                                "Key takeaway: install Python, confirm the version, and practice running `.py` files from the terminal."
                            ),
                            code_example="print(\"Hello from a file!\")",
                        ),
                        LessonSeed(
                            title="Your First Program",
                            duration_minutes=10,
                            order=3,
                            content=(
                                "The `print()` function displays output in the terminal.\n\n"
                                "Printing strings:\n\n"
                                "```python\n"
                                "print(\"Hello, World!\")\n"
                                "```\n\n"
                                "Printing multiple values: `print()` adds spaces by default.\n\n"
                                "```python\n"
                                "print(\"My name is\", \"Guido\")\n"
                                "```\n\n"
                                "Multiple print statements are common in small scripts:\n\n"
                                "```python\n"
                                "print(\"Line 1\")\n"
                                "print(\"Line 2\")\n"
                                "```\n\n"
                                "Comments start with `#` and are ignored by Python:\n\n"
                                "```python\n"
                                "# This is a comment\n"
                                "print(\"Code runs, comments don't\")\n"
                                "```\n\n"
                                "Key takeaway: `print()` is your basic tool for output and debugging when learning."
                            ),
                            code_example=(
                                "print(\"Hello, World!\")\n"
                                "print(\"My name is\", \"Guido\")\n"
                                "# A comment example\n"
                                "print(\"Done\")\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="What type of programming language is Python?",
                            option_a="Compiled",
                            option_b="Interpreted",
                            option_c="Assembly",
                            option_d="Machine",
                            correct_option="b",
                            explanation="Python is generally executed by an interpreter (bytecode on a VM), so it's commonly called an interpreted language.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="Who created Python?",
                            option_a="James Gosling",
                            option_b="Dennis Ritchie",
                            option_c="Guido van Rossum",
                            option_d="Bjarne Stroustrup",
                            correct_option="c",
                            explanation="Guido van Rossum created Python and released the first version in 1991.",
                        ),
                        QuizSeed(
                            order=3,
                            question_text="Which function is used to display output in Python?",
                            option_a="echo()",
                            option_b="console.log()",
                            option_c="print()",
                            option_d="display()",
                            correct_option="c",
                            explanation="`print()` writes text and values to standard output.",
                        ),
                    ],
                ),
                ModuleSeed(
                    title="Basics",
                    order=2,
                    description="Variables, input/output, and comments.",
                    lessons=[
                        LessonSeed(
                            title="Variables and Data Types",
                            duration_minutes=15,
                            order=1,
                            content=(
                                "A variable is a name that refers to a value. In Python, you don’t declare a type first — "
                                "the type is determined by the value you assign.\n\n"
                                "Examples:\n\n"
                                "```python\n"
                                "name = \"Alice\"      # str\n"
                                "age = 25            # int\n"
                                "price = 9.99        # float\n"
                                "is_active = True    # bool\n"
                                "```\n\n"
                                "You can check the type using `type()`:\n\n"
                                "```python\n"
                                "print(type(name))\n"
                                "print(type(age))\n"
                                "```\n\n"
                                "This is called **dynamic typing**: the variable can point to different types at different times.\n\n"
                                "Key takeaway: Python variables are flexible, but you should still keep your code clear and consistent."
                            ),
                            code_example=(
                                "name = \"Alice\"\n"
                                "age = 25\n"
                                "price = 9.99\n"
                                "is_active = True\n"
                                "print(type(name), type(age), type(price), type(is_active))\n"
                            ),
                        ),
                        LessonSeed(
                            title="Input and Output",
                            duration_minutes=12,
                            order=2,
                            content=(
                                "`input()` reads text from the user. Important: it always returns a string.\n\n"
                                "```python\n"
                                "name = input(\"Enter your name: \")\n"
                                "print(\"Hello\", name)\n"
                                "```\n\n"
                                "If you want numbers, convert with `int()` or `float()`:\n\n"
                                "```python\n"
                                "a = int(input(\"Enter a number: \"))\n"
                                "b = int(input(\"Enter another number: \"))\n"
                                "print(\"Sum:\", a + b)\n"
                                "```\n\n"
                                "Formatted strings (f-strings) make output cleaner:\n\n"
                                "```python\n"
                                "total = a + b\n"
                                "print(f\"{a} + {b} = {total}\")\n"
                                "```\n\n"
                                "Key takeaway: `input()` gives strings; convert types explicitly when doing math."
                            ),
                            code_example=(
                                "a = int(input(\"Enter a number: \"))\n"
                                "b = int(input(\"Enter another number: \"))\n"
                                "print(f\"{a} + {b} = {a + b}\")\n"
                            ),
                        ),
                        LessonSeed(
                            title="Comments",
                            duration_minutes=8,
                            order=3,
                            content=(
                                "Comments explain *why* something is done, not just *what* the code does.\n\n"
                                "Single-line comments start with `#`:\n\n"
                                "```python\n"
                                "# Convert user input to an integer before adding\n"
                                "age = int(input(\"Age: \"))\n"
                                "```\n\n"
                                "Multi-line notes are often written using triple quotes, but in practice these are string literals. "
                                "Use them sparingly for documentation blocks.\n\n"
                                "```python\n"
                                "\"\"\"This module contains simple helper functions.\"\"\"\n"
                                "```\n\n"
                                "Good comments are specific:\n"
                                "- Good: `# Avoid division by zero when user enters 0`\n"
                                "- Bad: `# Divide the numbers` (obvious)\n\n"
                                "Key takeaway: comment intent and constraints; keep comments accurate as code changes."
                            ),
                            code_example=(
                                "# Avoid division by zero when the user enters 0\n"
                                "den = int(input(\"Enter denominator: \"))\n"
                                "if den != 0:\n"
                                "    print(10 / den)\n"
                                "else:\n"
                                "    print(\"Cannot divide by zero\")\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="What is the data type of x = 3.14?",
                            option_a="int",
                            option_b="str",
                            option_c="float",
                            option_d="bool",
                            correct_option="c",
                            explanation="3.14 is a decimal number, so Python uses the float type.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="What does input() return by default?",
                            option_a="int",
                            option_b="float",
                            option_c="str",
                            option_d="bool",
                            correct_option="c",
                            explanation="`input()` always returns a string; you convert it if you need a number.",
                        ),
                        QuizSeed(
                            order=3,
                            question_text="How do you write a single-line comment in Python?",
                            option_a="// comment",
                            option_b="/* comment */",
                            option_c="# comment",
                            option_d="-- comment",
                            correct_option="c",
                            explanation="Python uses `#` for single-line comments.",
                        ),
                    ],
                ),
                ModuleSeed(
                    title="Operators and Conditions",
                    order=3,
                    description="Learn operators and control flow using if/elif/else.",
                    lessons=[
                        LessonSeed(
                            title="Operators",
                            duration_minutes=15,
                            order=1,
                            content=(
                                "Operators let you compute values and compare conditions.\n\n"
                                "Arithmetic operators:\n"
                                "- `+`, `-`, `*`, `/` (division gives float)\n"
                                "- `//` (floor division)\n"
                                "- `%` (remainder)\n"
                                "- `**` (power)\n\n"
                                "```python\n"
                                "print(10 + 3)\n"
                                "print(10 / 3)\n"
                                "print(10 // 3)\n"
                                "print(10 % 3)\n"
                                "print(2 ** 5)\n"
                                "```\n\n"
                                "Comparison operators: `==`, `!=`, `>`, `<`, `>=`, `<=`\n\n"
                                "Logical operators: `and`, `or`, `not`\n\n"
                                "Assignment operators: `=`, `+=`, `-=`, `*=`, `/=`\n\n"
                                "Key takeaway: operators are the building blocks of calculations and decisions."
                            ),
                            code_example=(
                                "x = 10\n"
                                "y = 3\n"
                                "print(x + y, x - y, x * y)\n"
                                "print(x / y, x // y, x % y)\n"
                                "print(x > y and y == 3)\n"
                                "x += 5\n"
                                "print(x)\n"
                            ),
                        ),
                        LessonSeed(
                            title="Conditional Statements",
                            duration_minutes=18,
                            order=2,
                            content=(
                                "Python uses `if`, `elif`, and `else` to run code based on conditions.\n\n"
                                "Syntax rules:\n"
                                "- A colon `:` ends the condition line\n"
                                "- Indentation defines the block\n\n"
                                "```python\n"
                                "n = int(input(\"Enter a number: \"))\n"
                                "if n > 0:\n"
                                "    print(\"Positive\")\n"
                                "elif n < 0:\n"
                                "    print(\"Negative\")\n"
                                "else:\n"
                                "    print(\"Zero\")\n"
                                "```\n\n"
                                "A practical example: grade calculator.\n\n"
                                "```python\n"
                                "score = int(input(\"Score: \"))\n"
                                "if score >= 90:\n"
                                "    grade = \"A\"\n"
                                "elif score >= 80:\n"
                                "    grade = \"B\"\n"
                                "elif score >= 70:\n"
                                "    grade = \"C\"\n"
                                "else:\n"
                                "    grade = \"D\"\n"
                                "print(\"Grade:\", grade)\n"
                                "```\n\n"
                                "Key takeaway: write clear conditions and keep indentation consistent."
                            ),
                            code_example=(
                                "score = 83\n"
                                "if score >= 90:\n"
                                "    grade = \"A\"\n"
                                "elif score >= 80:\n"
                                "    grade = \"B\"\n"
                                "elif score >= 70:\n"
                                "    grade = \"C\"\n"
                                "else:\n"
                                "    grade = \"D\"\n"
                                "print(grade)\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="What is the result of 17 % 5?",
                            option_a="3",
                            option_b="2",
                            option_c="3.4",
                            option_d="12",
                            correct_option="b",
                            explanation="17 divided by 5 gives remainder 2, so 17 % 5 is 2.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="Which keyword is used for else-if in Python?",
                            option_a="else if",
                            option_b="elseif",
                            option_c="elif",
                            option_d="elsif",
                            correct_option="c",
                            explanation="Python uses `elif` as the 'else-if' keyword.",
                        ),
                    ],
                ),
                ModuleSeed(
                    title="Loops",
                    order=4,
                    description="Repeat work with for/while, and control loops with break/continue.",
                    lessons=[
                        LessonSeed(
                            title="for and while Loops",
                            duration_minutes=20,
                            order=1,
                            content=(
                                "Loops run code multiple times.\n\n"
                                "`for` loops are great when you know how many times you want to repeat something:\n\n"
                                "```python\n"
                                "for i in range(1, 11):\n"
                                "    print(i)\n"
                                "```\n\n"
                                "You can iterate over lists and strings:\n\n"
                                "```python\n"
                                "items = [\"apple\", \"banana\", \"cherry\"]\n"
                                "for item in items:\n"
                                "    print(item)\n"
                                "```\n\n"
                                "`while` loops repeat while a condition stays true:\n\n"
                                "```python\n"
                                "n = 5\n"
                                "total = 0\n"
                                "while n > 0:\n"
                                "    total += n\n"
                                "    n -= 1\n"
                                "print(total)\n"
                                "```\n\n"
                                "Key takeaway: use `for` for sequences and `while` for condition-controlled repetition."
                            ),
                            code_example=(
                                "n = 10\n"
                                "total = 0\n"
                                "for i in range(1, n + 1):\n"
                                "    total += i\n"
                                "print(total)\n"
                            ),
                        ),
                        LessonSeed(
                            title="Break and Continue",
                            duration_minutes=12,
                            order=2,
                            content=(
                                "`break` exits a loop immediately. `continue` skips to the next iteration.\n\n"
                                "Example: stop when a target is found.\n\n"
                                "```python\n"
                                "nums = [3, 8, 2, 10, 7]\n"
                                "target = 10\n"
                                "for n in nums:\n"
                                "    if n == target:\n"
                                "        print(\"Found!\")\n"
                                "        break\n"
                                "```\n\n"
                                "Example: print only odd numbers.\n\n"
                                "```python\n"
                                "for i in range(1, 11):\n"
                                "    if i % 2 == 0:\n"
                                "        continue\n"
                                "    print(i)\n"
                                "```\n\n"
                                "Key takeaway: `break` stops; `continue` skips."
                            ),
                            code_example=(
                                "for i in range(1, 11):\n"
                                "    if i == 5:\n"
                                "        continue\n"
                                "    if i == 9:\n"
                                "        break\n"
                                "    print(i)\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="How many times does for i in range(5) loop?",
                            option_a="4",
                            option_b="5",
                            option_c="6",
                            option_d="Infinite",
                            correct_option="b",
                            explanation="range(5) produces 0,1,2,3,4 which is 5 values.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="What does break do?",
                            option_a="Skips iteration",
                            option_b="Exits the loop",
                            option_c="Restarts the loop",
                            option_d="Pauses the loop",
                            correct_option="b",
                            explanation="`break` terminates the nearest enclosing loop immediately.",
                        ),
                        QuizSeed(
                            order=3,
                            question_text="What does range(2, 8, 2) produce?",
                            option_a="2,4,6",
                            option_b="2,3,4,5,6,7",
                            option_c="2,4,6,8",
                            option_d="2,3,4,5,6,7,8",
                            correct_option="a",
                            explanation="range(start, stop, step) stops before 8, so it yields 2,4,6.",
                        ),
                    ],
                ),
                ModuleSeed(
                    title="Data Structures",
                    order=5,
                    description="Work with strings, lists, tuples, sets, and dictionaries.",
                    lessons=[
                        LessonSeed(
                            title="Strings",
                            duration_minutes=15,
                            order=1,
                            content=(
                                "Strings represent text. You can create strings with single or double quotes.\n\n"
                                "Indexing and slicing:\n\n"
                                "```python\n"
                                "s = \"hello\"\n"
                                "print(s[0])      # h\n"
                                "print(s[1:3])    # el\n"
                                "```\n\n"
                                "Useful methods:\n"
                                "- `upper()`, `lower()`\n"
                                "- `strip()`\n"
                                "- `split()` and `\" \".join()`\n"
                                "- `replace()`, `find()`\n\n"
                                "Strings are **immutable**, meaning you can't change them in place.\n\n"
                                "```python\n"
                                "name = \"guido\"\n"
                                "name = name.capitalize()\n"
                                "print(name)\n"
                                "```\n\n"
                                "Key takeaway: use slicing and methods to work with strings; reassign when you need changes."
                            ),
                            code_example=(
                                "s = \"  hello world  \"\n"
                                "print(s.strip())\n"
                                "print(s.upper())\n"
                                "print(\"-\".join(s.strip().split()))\n"
                            ),
                        ),
                        LessonSeed(
                            title="Lists",
                            duration_minutes=18,
                            order=2,
                            content=(
                                "Lists store ordered collections of items and are mutable.\n\n"
                                "Creating and accessing:\n\n"
                                "```python\n"
                                "nums = [1, 2, 3]\n"
                                "print(nums[0])\n"
                                "```\n\n"
                                "Common methods:\n"
                                "- `append()`, `insert()`\n"
                                "- `remove()`, `pop()`\n"
                                "- `sort()`, `reverse()`\n\n"
                                "List slicing:\n\n"
                                "```python\n"
                                "print(nums[1:])\n"
                                "```\n\n"
                                "List comprehensions are a clean way to build lists:\n\n"
                                "```python\n"
                                "squares = [x * x for x in range(1, 6)]\n"
                                "```\n\n"
                                "Key takeaway: lists are flexible and perfect for collections you need to modify."
                            ),
                            code_example=(
                                "nums = [3, 1, 4]\n"
                                "nums.append(2)\n"
                                "nums.sort()\n"
                                "print(nums)\n"
                                "evens = [n for n in nums if n % 2 == 0]\n"
                                "print(evens)\n"
                            ),
                        ),
                        LessonSeed(
                            title="Tuples",
                            duration_minutes=12,
                            order=3,
                            content=(
                                "Tuples are like lists, but **immutable**. Use tuples for fixed collections.\n\n"
                                "```python\n"
                                "point = (10, 20)\n"
                                "x, y = point\n"
                                "print(x, y)\n"
                                "```\n\n"
                                "A single-item tuple needs a comma:\n\n"
                                "```python\n"
                                "single = (42,)\n"
                                "```\n\n"
                                "Tuples support `count()` and `index()`.\n\n"
                                "Key takeaway: choose tuples when you want data to stay unchanged."
                            ),
                            code_example=(
                                "rgb = (255, 200, 0)\n"
                                "print(rgb[0])\n"
                                "print((1, 2, 2, 3).count(2))\n"
                            ),
                        ),
                        LessonSeed(
                            title="Sets",
                            duration_minutes=12,
                            order=4,
                            content=(
                                "Sets store **unique** items and are unordered.\n\n"
                                "```python\n"
                                "nums = {1, 2, 2, 3}\n"
                                "print(nums)  # {1, 2, 3}\n"
                                "```\n\n"
                                "Useful operations:\n"
                                "- `add()`, `discard()`, `remove()`\n"
                                "- union: `a | b`\n"
                                "- intersection: `a & b`\n"
                                "- difference: `a - b`\n\n"
                                "Sets are great for membership checks:\n\n"
                                "```python\n"
                                "seen = set()\n"
                                "seen.add(\"alice\")\n"
                                "print(\"alice\" in seen)\n"
                                "```\n\n"
                                "Key takeaway: sets automatically remove duplicates and support fast membership tests."
                            ),
                            code_example=(
                                "a = {1, 2, 3}\n"
                                "b = {3, 4, 5}\n"
                                "print(a | b)\n"
                                "print(a & b)\n"
                                "print(a - b)\n"
                            ),
                        ),
                        LessonSeed(
                            title="Dictionaries",
                            duration_minutes=18,
                            order=5,
                            content=(
                                "Dictionaries map keys to values.\n\n"
                                "Creating and reading:\n\n"
                                "```python\n"
                                "user = {\"name\": \"Alice\", \"age\": 25}\n"
                                "print(user[\"name\"])\n"
                                "print(user.get(\"email\", \"not set\"))\n"
                                "```\n\n"
                                "Updating:\n\n"
                                "```python\n"
                                "user[\"age\"] = 26\n"
                                "user[\"email\"] = \"alice@example.com\"\n"
                                "```\n\n"
                                "Looping:\n\n"
                                "```python\n"
                                "for k, v in user.items():\n"
                                "    print(k, v)\n"
                                "```\n\n"
                                "Key takeaway: dicts are the go-to structure for labeled data."
                            ),
                            code_example=(
                                "inventory = {\"apples\": 10, \"bananas\": 5}\n"
                                "inventory[\"apples\"] += 2\n"
                                "for item, qty in inventory.items():\n"
                                "    print(f\"{item}: {qty}\")\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="Which data structure does NOT allow duplicates?",
                            option_a="List",
                            option_b="Tuple",
                            option_c="Set",
                            option_d="Dictionary values",
                            correct_option="c",
                            explanation="Sets store unique items, so duplicates are removed automatically.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="What is the output of \"hello\"[1:3]?",
                            option_a="\"he\"",
                            option_b="\"el\"",
                            option_c="\"ell\"",
                            option_d="\"hel\"",
                            correct_option="b",
                            explanation="Slicing is start-inclusive, end-exclusive: indices 1 and 2 are 'e' and 'l'.",
                        ),
                        QuizSeed(
                            order=3,
                            question_text="How do you add a key-value pair to a dictionary d?",
                            option_a="d.add(\"key\", \"val\")",
                            option_b="d.append(\"key\": \"val\")",
                            option_c="d[\"key\"] = \"val\"",
                            option_d="d.insert(\"key\", \"val\")",
                            correct_option="c",
                            explanation="Dictionaries use square bracket assignment to create or update a key.",
                        ),
                    ],
                ),
                ModuleSeed(
                    title="Mini Projects",
                    order=6,
                    description="Apply fundamentals by building small but complete programs.",
                    lessons=[
                        LessonSeed(
                            title="Calculator Project",
                            duration_minutes=25,
                            order=1,
                            content=(
                                "In this project you’ll build a simple calculator that:\n"
                                "- Reads two numbers\n"
                                "- Reads an operator (`+`, `-`, `*`, `/`)\n"
                                "- Calculates the result using `if/elif/else`\n"
                                "- Prevents division by zero\n\n"
                                "Step 1: Read inputs and convert to numbers.\n\n"
                                "Step 2: Decide which operation to perform.\n\n"
                                "Step 3: Print the result.\n\n"
                                "Here’s a complete working version:\n\n"
                                "```python\n"
                                "a = float(input(\"Enter first number: \"))\n"
                                "op = input(\"Enter operator (+, -, *, /): \").strip()\n"
                                "b = float(input(\"Enter second number: \"))\n"
                                "\n"
                                "if op == \"+\":\n"
                                "    result = a + b\n"
                                "elif op == \"-\":\n"
                                "    result = a - b\n"
                                "elif op == \"*\":\n"
                                "    result = a * b\n"
                                "elif op == \"/\":\n"
                                "    if b == 0:\n"
                                "        print(\"Error: division by zero\")\n"
                                "        result = None\n"
                                "    else:\n"
                                "        result = a / b\n"
                                "else:\n"
                                "    print(\"Unknown operator\")\n"
                                "    result = None\n"
                                "\n"
                                "if result is not None:\n"
                                "    print(f\"{a} {op} {b} = {result}\")\n"
                                "```\n\n"
                                "Key takeaway: projects are just the basics combined in a clean flow."
                            ),
                            code_example=(
                                "a = float(input(\"Enter first number: \"))\n"
                                "op = input(\"Enter operator (+, -, *, /): \").strip()\n"
                                "b = float(input(\"Enter second number: \"))\n"
                                "\n"
                                "if op == \"+\":\n"
                                "    print(a + b)\n"
                                "elif op == \"-\":\n"
                                "    print(a - b)\n"
                                "elif op == \"*\":\n"
                                "    print(a * b)\n"
                                "elif op == \"/\":\n"
                                "    if b == 0:\n"
                                "        print(\"Error: division by zero\")\n"
                                "    else:\n"
                                "        print(a / b)\n"
                                "else:\n"
                                "    print(\"Unknown operator\")\n"
                            ),
                        ),
                        LessonSeed(
                            title="Number Guessing Game",
                            duration_minutes=25,
                            order=2,
                            content=(
                                "This game picks a random number and asks the player to guess it.\n\n"
                                "Core ideas you’ll practice:\n"
                                "- Importing a module (`random`)\n"
                                "- Using a `while` loop\n"
                                "- Comparing numbers and giving hints\n"
                                "- Counting attempts\n\n"
                                "Complete working code:\n\n"
                                "```python\n"
                                "import random\n"
                                "\n"
                                "secret = random.randint(1, 100)\n"
                                "attempts = 0\n"
                                "\n"
                                "while True:\n"
                                "    guess = int(input(\"Guess a number (1-100): \"))\n"
                                "    attempts += 1\n"
                                "\n"
                                "    if guess < secret:\n"
                                "        print(\"Too low\")\n"
                                "    elif guess > secret:\n"
                                "        print(\"Too high\")\n"
                                "    else:\n"
                                "        print(f\"Correct! You guessed it in {attempts} attempts.\")\n"
                                "        break\n"
                                "```\n\n"
                                "Key takeaway: loops + conditions let you build interactive programs."
                            ),
                            code_example=(
                                "import random\n"
                                "secret = random.randint(1, 100)\n"
                                "attempts = 0\n"
                                "while True:\n"
                                "    guess = int(input(\"Guess (1-100): \"))\n"
                                "    attempts += 1\n"
                                "    if guess < secret:\n"
                                "        print(\"Too low\")\n"
                                "    elif guess > secret:\n"
                                "        print(\"Too high\")\n"
                                "    else:\n"
                                "        print(f\"Correct in {attempts} attempts\")\n"
                                "        break\n"
                            ),
                        ),
                    ],
                    quiz=[
                        QuizSeed(
                            order=1,
                            question_text="Which module is used to generate random numbers?",
                            option_a="math",
                            option_b="random",
                            option_c="os",
                            option_d="sys",
                            correct_option="b",
                            explanation="Python's `random` module provides functions like randint() for random values.",
                        ),
                        QuizSeed(
                            order=2,
                            question_text="What handles division by zero in the calculator project?",
                            option_a="for loop",
                            option_b="while loop",
                            option_c="if condition",
                            option_d="try-except",
                            correct_option="c",
                            explanation="The calculator checks `if b == 0` before dividing, preventing a crash.",
                        ),
                    ],
                ),
            ],
        ),
        # Courses 2-5 are seeded below with full content and quizzes.
        _intermediate_python(),
        _oop_python(),
        _dsa_python(),
        _guided_project(),
    ]


def _intermediate_python() -> CourseSeed:
    return CourseSeed(
        title="Intermediate Python",
        slug="intermediate-python",
        description=(
            "Level up your Python: write clean functions, use *args/**kwargs, recursion, file handling with JSON, and robust exception handling. "
            "Finish by building a file-based contact manager."
        ),
        difficulty="intermediate",
        color_hex="#FF9800",
        icon="intermediate",
        estimated_hours=10,
        order=2,
        is_published=True,
        modules=[
            ModuleSeed(
                title="Functions",
                order=1,
                description="Break problems into reusable blocks of code.",
                lessons=[
                    LessonSeed(
                        title="Functions",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "A function is a reusable block of code defined with `def`.\n\n"
                            "Why functions matter:\n"
                            "- Reduce repetition\n"
                            "- Make code easier to test and maintain\n"
                            "- Give names to ideas (greet, add, validate)\n\n"
                            "Basic examples:\n\n"
                            "```python\n"
                            "def greet(name):\n"
                            "    print(f\"Hello, {name}!\")\n"
                            "\n"
                            "def add(a, b):\n"
                            "    return a + b\n"
                            "\n"
                            "def is_even(n):\n"
                            "    return n % 2 == 0\n"
                            "\n"
                            "greet(\"Amina\")\n"
                            "print(add(2, 3))\n"
                            "print(is_even(10))\n"
                            "```\n\n"
                            "Key takeaway: functions help you write code once and reuse it many times."
                        ),
                        code_example=(
                            "def is_even(n):\n"
                            "    return n % 2 == 0\n"
                            "\n"
                            "print(is_even(7))\n"
                        ),
                    ),
                    LessonSeed(
                        title="Parameters and Return",
                        duration_minutes=18,
                        order=2,
                        content=(
                            "Parameters are the names in the function definition. Arguments are the values you pass in.\n\n"
                            "Positional vs keyword arguments:\n\n"
                            "```python\n"
                            "def power(base, exp=2):\n"
                            "    return base ** exp\n"
                            "\n"
                            "print(power(3))        # positional, default exp\n"
                            "print(power(3, 3))     # positional\n"
                            "print(power(base=2, exp=5))  # keyword\n"
                            "```\n\n"
                            "Returning multiple values (as a tuple):\n\n"
                            "```python\n"
                            "def min_max(nums):\n"
                            "    return min(nums), max(nums)\n"
                            "\n"
                            "mn, mx = min_max([3, 9, 1])\n"
                            "print(mn, mx)\n"
                            "```\n\n"
                            "Scope basics:\n"
                            "- Variables inside a function are local by default.\n\n"
                            "Key takeaway: defaults and keyword args make functions easier to use and safer to call."
                        ),
                        code_example=(
                            "def min_max(nums):\n"
                            "    return min(nums), max(nums)\n"
                            "\n"
                            "mn, mx = min_max([5, 2, 9])\n"
                            "print(mn, mx)\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What keyword defines a function in Python?",
                        option_a="function",
                        option_b="func",
                        option_c="def",
                        option_d="define",
                        correct_option="c",
                        explanation="Functions are defined using the `def` keyword.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What does a function return if there is no return statement?",
                        option_a="0",
                        option_b="\"\"",
                        option_c="None",
                        option_d="False",
                        correct_option="c",
                        explanation="If there’s no explicit return, Python returns `None`.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="What is the scope of a variable defined inside a function?",
                        option_a="Global",
                        option_b="Local",
                        option_c="Universal",
                        option_d="Static",
                        correct_option="b",
                        explanation="Variables created inside a function are local to that function.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Advanced Functions",
                order=2,
                description="Flexible function signatures and small anonymous functions.",
                lessons=[
                    LessonSeed(
                        title="*args and **kwargs",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "`*args` collects extra positional arguments into a tuple.\n"
                            "`**kwargs` collects extra keyword arguments into a dictionary.\n\n"
                            "```python\n"
                            "def total(*args):\n"
                            "    return sum(args)\n"
                            "\n"
                            "print(total(1, 2, 3))\n"
                            "```\n\n"
                            "```python\n"
                            "def profile(**kwargs):\n"
                            "    for k, v in kwargs.items():\n"
                            "        print(k, v)\n"
                            "\n"
                            "profile(name=\"Amina\", city=\"Lahore\")\n"
                            "```\n\n"
                            "You can combine normal params with `*args` and `**kwargs`, and also unpack values:\n\n"
                            "```python\n"
                            "nums = [1, 2, 3]\n"
                            "print(total(*nums))\n"
                            "```\n\n"
                            "Key takeaway: `*args/**kwargs` make APIs flexible while keeping the call site readable."
                        ),
                        code_example=(
                            "def show(first, *args, **kwargs):\n"
                            "    print(first)\n"
                            "    print(args)\n"
                            "    print(kwargs)\n"
                            "\n"
                            "show(\"start\", 10, 20, debug=True)\n"
                        ),
                    ),
                    LessonSeed(
                        title="Lambda Functions",
                        duration_minutes=12,
                        order=2,
                        content=(
                            "A lambda is an anonymous function written in one expression.\n\n"
                            "Syntax:\n\n"
                            "```python\n"
                            "square = lambda x: x * x\n"
                            "print(square(5))\n"
                            "```\n\n"
                            "Common uses: `sorted`, `map`, `filter`.\n\n"
                            "```python\n"
                            "pairs = [(\"b\", 2), (\"a\", 3), (\"c\", 1)]\n"
                            "pairs_sorted = sorted(pairs, key=lambda p: p[1])\n"
                            "print(pairs_sorted)\n"
                            "```\n\n"
                            "Choose a regular `def` when logic is complex or multi-step.\n\n"
                            "Key takeaway: lambdas are for small transformations, not full programs."
                        ),
                        code_example="print(sorted([\"apple\", \"pear\", \"banana\"], key=lambda s: len(s)))",
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What does *args collect?",
                        option_a="Keyword arguments",
                        option_b="Positional arguments as tuple",
                        option_c="A list",
                        option_d="A dictionary",
                        correct_option="b",
                        explanation="`*args` collects extra positional arguments into a tuple.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Lambda functions can contain?",
                        option_a="Multiple statements",
                        option_b="Only one expression",
                        option_c="Loops",
                        option_d="Classes",
                        correct_option="b",
                        explanation="A lambda is limited to a single expression (no statements like loops/assignments).",
                    ),
                ],
            ),
            ModuleSeed(
                title="Recursion",
                order=3,
                description="Solve problems by calling a function from itself.",
                lessons=[
                    LessonSeed(
                        title="Recursion Basics and Examples",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "Recursion is when a function calls itself to solve a smaller version of the same problem.\n\n"
                            "Every recursive function needs:\n"
                            "- A **base case** (stops recursion)\n"
                            "- A **recursive case** (moves toward the base case)\n\n"
                            "Factorial example:\n\n"
                            "```python\n"
                            "def factorial(n):\n"
                            "    if n == 0:\n"
                            "        return 1\n"
                            "    return n * factorial(n - 1)\n"
                            "\n"
                            "print(factorial(5))\n"
                            "```\n\n"
                            "Fibonacci example:\n\n"
                            "```python\n"
                            "def fib(n):\n"
                            "    if n <= 1:\n"
                            "        return n\n"
                            "    return fib(n - 1) + fib(n - 2)\n"
                            "```\n\n"
                            "Recursion uses the call stack, so deep recursion can cause a stack overflow.\n\n"
                            "Key takeaway: recursion is powerful for tree-like problems, but always define a clear base case."
                        ),
                        code_example=(
                            "def factorial(n):\n"
                            "    if n == 0:\n"
                            "        return 1\n"
                            "    return n * factorial(n - 1)\n"
                            "\n"
                            "print(factorial(6))\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What must every recursive function have?",
                        option_a="A loop",
                        option_b="A base case",
                        option_c="A global variable",
                        option_d="A class",
                        correct_option="b",
                        explanation="The base case stops recursion so the function doesn’t call itself forever.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What is factorial(0)?",
                        option_a="0",
                        option_b="1",
                        option_c="Undefined",
                        option_d="Error",
                        correct_option="b",
                        explanation="By definition, factorial(0) is 1.",
                    ),
                ],
            ),
            ModuleSeed(
                title="File Handling",
                order=4,
                description="Read/write files and work with JSON data.",
                lessons=[
                    LessonSeed(
                        title="Read and Write Files",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "Python reads and writes files using `open()`.\n\n"
                            "Common modes:\n"
                            "- `r` read\n"
                            "- `w` write (overwrites)\n"
                            "- `a` append\n\n"
                            "Always prefer `with` so the file is closed automatically:\n\n"
                            "```python\n"
                            "with open(\"notes.txt\", \"w\", encoding=\"utf-8\") as f:\n"
                            "    f.write(\"Hello\\n\")\n"
                            "    f.write(\"File handling!\\n\")\n"
                            "\n"
                            "with open(\"notes.txt\", \"r\", encoding=\"utf-8\") as f:\n"
                            "    content = f.read()\n"
                            "    print(content)\n"
                            "```\n\n"
                            "Key takeaway: `with open(...)` is the safest pattern for file I/O."
                        ),
                        code_example=(
                            "with open(\"example.txt\", \"w\", encoding=\"utf-8\") as f:\n"
                            "    f.write(\"Line 1\\nLine 2\\n\")\n"
                            "\n"
                            "with open(\"example.txt\", \"r\", encoding=\"utf-8\") as f:\n"
                            "    for line in f:\n"
                            "        print(line.strip())\n"
                        ),
                    ),
                    LessonSeed(
                        title="JSON Basics",
                        duration_minutes=15,
                        order=2,
                        content=(
                            "JSON is a text format for structured data (objects, arrays, strings, numbers).\n\n"
                            "In Python, use the built-in `json` module.\n\n"
                            "Convert a dictionary to JSON text:\n\n"
                            "```python\n"
                            "import json\n"
                            "data = {\"name\": \"Amina\", \"age\": 25}\n"
                            "s = json.dumps(data)\n"
                            "print(s)\n"
                            "```\n\n"
                            "Write JSON to a file and read it back:\n\n"
                            "```python\n"
                            "import json\n"
                            "data = {\"users\": [{\"name\": \"Amina\"}]}\n"
                            "\n"
                            "with open(\"data.json\", \"w\", encoding=\"utf-8\") as f:\n"
                            "    json.dump(data, f, indent=2)\n"
                            "\n"
                            "with open(\"data.json\", \"r\", encoding=\"utf-8\") as f:\n"
                            "    loaded = json.load(f)\n"
                            "print(loaded[\"users\"][0][\"name\"])\n"
                            "```\n\n"
                            "Key takeaway: JSON is perfect for saving structured app data like settings or contacts."
                        ),
                        code_example=(
                            "import json\n"
                            "user = {\"name\": \"Amina\", \"skills\": [\"python\", \"django\"]}\n"
                            "text = json.dumps(user)\n"
                            "print(text)\n"
                            "parsed = json.loads(text)\n"
                            "print(parsed[\"skills\"]) \n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Which mode opens a file for writing and creates it if it doesn't exist?",
                        option_a="\"r\"",
                        option_b="\"w\"",
                        option_c="\"x\"",
                        option_d="\"a\"",
                        correct_option="b",
                        explanation="`w` opens a file for writing and creates it if missing (overwrites if present).",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What does the with statement ensure?",
                        option_a="Faster execution",
                        option_b="File is properly closed",
                        option_c="File is encrypted",
                        option_d="File is compressed",
                        correct_option="b",
                        explanation="`with` closes the file even if an error occurs.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="Which function converts a Python dict to a JSON string?",
                        option_a="json.load()",
                        option_b="json.dumps()",
                        option_c="json.parse()",
                        option_d="json.stringify()",
                        correct_option="b",
                        explanation="`json.dumps()` serializes a Python object to a JSON-formatted string.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Exception Handling",
                order=5,
                description="Make programs robust with try/except and custom exceptions.",
                lessons=[
                    LessonSeed(
                        title="Try and Except",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Exceptions are runtime errors that stop your program unless handled.\n\n"
                            "Basic try/except:\n\n"
                            "```python\n"
                            "try:\n"
                            "    n = int(input(\"Enter a number: \"))\n"
                            "    print(10 / n)\n"
                            "except ValueError:\n"
                            "    print(\"Please enter a valid integer\")\n"
                            "except ZeroDivisionError:\n"
                            "    print(\"Cannot divide by zero\")\n"
                            "```\n\n"
                            "You can add `else` (runs if no exception) and `finally` (always runs).\n\n"
                            "Key takeaway: catch specific exceptions so you handle errors correctly."
                        ),
                        code_example=(
                            "try:\n"
                            "    n = int(input(\"n: \"))\n"
                            "except ValueError:\n"
                            "    print(\"Not an int\")\n"
                            "else:\n"
                            "    print(\"ok\")\n"
                            "finally:\n"
                            "    print(\"done\")\n"
                        ),
                    ),
                    LessonSeed(
                        title="Custom Errors",
                        duration_minutes=12,
                        order=2,
                        content=(
                            "You can define your own exceptions by inheriting from `Exception`.\n\n"
                            "```python\n"
                            "class NegativeBalanceError(Exception):\n"
                            "    pass\n"
                            "\n"
                            "def withdraw(balance, amount):\n"
                            "    if amount > balance:\n"
                            "        raise NegativeBalanceError(\"Insufficient funds\")\n"
                            "    return balance - amount\n"
                            "```\n\n"
                            "Custom exceptions make errors more meaningful and easier to handle.\n\n"
                            "Key takeaway: raise custom errors when built-in exceptions don’t describe the problem well."
                        ),
                        code_example=(
                            "class AgeTooLowError(Exception):\n"
                            "    pass\n"
                            "\n"
                            "def check_age(age):\n"
                            "    if age < 18:\n"
                            "        raise AgeTooLowError(\"Must be 18+\")\n"
                            "\n"
                            "try:\n"
                            "    check_age(15)\n"
                            "except AgeTooLowError as e:\n"
                            "    print(e)\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Which block runs only if no exception occurs?",
                        option_a="except",
                        option_b="finally",
                        option_c="else",
                        option_d="try",
                        correct_option="c",
                        explanation="The `else` block runs after try if no exception was raised.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="How do you manually raise an exception?",
                        option_a="throw",
                        option_b="raise",
                        option_c="except",
                        option_d="error",
                        correct_option="b",
                        explanation="Use the `raise` keyword to raise an exception in Python.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Modules and Packages",
                order=6,
                description="Organize code and use Python's standard library and packages.",
                lessons=[
                    LessonSeed(
                        title="Importing Modules",
                        duration_minutes=12,
                        order=1,
                        content=(
                            "Modules are Python files you can import to reuse code.\n\n"
                            "```python\n"
                            "import math\n"
                            "print(math.sqrt(16))\n"
                            "```\n\n"
                            "Import specific items:\n\n"
                            "```python\n"
                            "from datetime import datetime\n"
                            "print(datetime.utcnow())\n"
                            "```\n\n"
                            "Use aliases:\n\n"
                            "```python\n"
                            "import random as rnd\n"
                            "print(rnd.randint(1, 10))\n"
                            "```\n\n"
                            "Explore a module using `dir()`.\n\n"
                            "Key takeaway: imports keep your code clean and avoid rewriting helpers."
                        ),
                        code_example=(
                            "import os\n"
                            "print(os.getcwd())\n"
                        ),
                    ),
                    LessonSeed(
                        title="Creating Your Own Modules",
                        duration_minutes=15,
                        order=2,
                        content=(
                            "Any `.py` file can be a module.\n\n"
                            "Example structure:\n"
                            "- `utils.py`\n"
                            "- `main.py`\n\n"
                            "`utils.py`:\n\n"
                            "```python\n"
                            "def clamp(n, low, high):\n"
                            "    return max(low, min(n, high))\n"
                            "```\n\n"
                            "`main.py`:\n\n"
                            "```python\n"
                            "from utils import clamp\n"
                            "print(clamp(15, 0, 10))\n"
                            "```\n\n"
                            "The `if __name__ == \"__main__\":` guard runs code only when the file is executed directly.\n\n"
                            "Key takeaway: modules and packages help you scale projects without messy files."
                        ),
                        code_example=(
                            "def clamp(n, low, high):\n"
                            "    return max(low, min(n, high))\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What is used to install external packages?",
                        option_a="npm",
                        option_b="pip",
                        option_c="brew",
                        option_d="apt",
                        correct_option="b",
                        explanation="`pip` is Python's package installer for downloading packages from PyPI.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What does if __name__ == \"__main__\" check?",
                        option_a="If module is imported",
                        option_b="If module is run directly",
                        option_c="If module exists",
                        option_d="If module is updated",
                        correct_option="b",
                        explanation="It’s true only when the file is executed as the main program, not imported.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Project",
                order=7,
                description="Build a real CLI project with JSON persistence.",
                lessons=[
                    LessonSeed(
                        title="Contact Manager Project",
                        duration_minutes=30,
                        order=1,
                        content=(
                            "You’ll build a file-based contact manager with these features:\n"
                            "- Add a contact (name, phone, email)\n"
                            "- View all contacts\n"
                            "- Search by name\n"
                            "- Delete a contact\n"
                            "- Save/load contacts in a JSON file\n\n"
                            "Design approach:\n"
                            "- Keep contacts in memory as a list of dictionaries\n"
                            "- Use functions for each action\n"
                            "- Use a `while True` loop for the menu\n\n"
                            "Complete working code:\n\n"
                            "```python\n"
                            "import json\n"
                            "import os\n"
                            "\n"
                            "FILE = \"contacts.json\"\n"
                            "\n"
                            "def load_contacts():\n"
                            "    if not os.path.exists(FILE):\n"
                            "        return []\n"
                            "    with open(FILE, \"r\", encoding=\"utf-8\") as f:\n"
                            "        return json.load(f)\n"
                            "\n"
                            "def save_contacts(contacts):\n"
                            "    with open(FILE, \"w\", encoding=\"utf-8\") as f:\n"
                            "        json.dump(contacts, f, indent=2)\n"
                            "\n"
                            "def add_contact(contacts):\n"
                            "    name = input(\"Name: \").strip()\n"
                            "    phone = input(\"Phone: \").strip()\n"
                            "    email = input(\"Email: \").strip()\n"
                            "    contacts.append({\"name\": name, \"phone\": phone, \"email\": email})\n"
                            "\n"
                            "def list_contacts(contacts):\n"
                            "    if not contacts:\n"
                            "        print(\"No contacts yet\")\n"
                            "        return\n"
                            "    for i, c in enumerate(contacts, start=1):\n"
                            "        print(f\"{i}. {c['name']} | {c['phone']} | {c['email']}\")\n"
                            "\n"
                            "def search_contacts(contacts):\n"
                            "    q = input(\"Search name: \").strip().lower()\n"
                            "    results = [c for c in contacts if q in c[\"name\"].lower()]\n"
                            "    for c in results:\n"
                            "        print(f\"{c['name']} | {c['phone']} | {c['email']}\")\n"
                            "    if not results:\n"
                            "        print(\"No matches\")\n"
                            "\n"
                            "def delete_contact(contacts):\n"
                            "    list_contacts(contacts)\n"
                            "    if not contacts:\n"
                            "        return\n"
                            "    idx = int(input(\"Delete which number? \"))\n"
                            "    if 1 <= idx <= len(contacts):\n"
                            "        removed = contacts.pop(idx - 1)\n"
                            "        print(f\"Deleted {removed['name']}\")\n"
                            "    else:\n"
                            "        print(\"Invalid selection\")\n"
                            "\n"
                            "def main():\n"
                            "    contacts = load_contacts()\n"
                            "    while True:\n"
                            "        print(\"\\n1) Add  2) View  3) Search  4) Delete  5) Save & Exit\")\n"
                            "        choice = input(\"> \").strip()\n"
                            "        if choice == \"1\":\n"
                            "            add_contact(contacts)\n"
                            "        elif choice == \"2\":\n"
                            "            list_contacts(contacts)\n"
                            "        elif choice == \"3\":\n"
                            "            search_contacts(contacts)\n"
                            "        elif choice == \"4\":\n"
                            "            delete_contact(contacts)\n"
                            "        elif choice == \"5\":\n"
                            "            save_contacts(contacts)\n"
                            "            print(\"Saved. Bye!\")\n"
                            "            break\n"
                            "        else:\n"
                            "            print(\"Choose 1-5\")\n"
                            "\n"
                            "if __name__ == \"__main__\":\n"
                            "    main()\n"
                            "```\n\n"
                            "Key takeaway: this project combines functions, loops, file I/O, JSON, and validation into a real tool."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Which data format is ideal for storing structured contact data?",
                        option_a="Plain text",
                        option_b="CSV",
                        option_c="JSON",
                        option_d="XML",
                        correct_option="c",
                        explanation="JSON maps naturally to dictionaries/lists, making it great for structured contact data.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What function would you use to check if a file exists?",
                        option_a="file.check()",
                        option_b="os.path.exists()",
                        option_c="file.exists()",
                        option_d="path.check()",
                        correct_option="b",
                        explanation="`os.path.exists(path)` returns True if the file or directory exists.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="In the contact manager, what data structure holds contacts in memory?",
                        option_a="Tuple",
                        option_b="Set",
                        option_c="List of dictionaries",
                        option_d="String",
                        correct_option="c",
                        explanation="Each contact is a dictionary; all contacts are stored in a list.",
                    ),
                ],
            ),
        ],
    )


def _oop_python() -> CourseSeed:
    return CourseSeed(
        title="Object-Oriented Programming",
        slug="oop-python",
        description=(
            "Master OOP in Python: classes, constructors, encapsulation, inheritance, polymorphism, and abstraction. "
            "Build a banking system project using clean object design."
        ),
        difficulty="intermediate",
        color_hex="#2196F3",
        icon="oop",
        estimated_hours=8,
        order=3,
        is_published=True,
        modules=[
            ModuleSeed(
                title="OOP Basics",
                order=1,
                description="Learn classes, objects, attributes, and methods.",
                lessons=[
                    LessonSeed(
                        title="Classes and Objects",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "Object-Oriented Programming (OOP) organizes code around **objects**.\n\n"
                            "- A **class** is a blueprint (definition).\n"
                            "- An **object** is an instance created from a class.\n\n"
                            "A simple class:\n\n"
                            "```python\n"
                            "class Dog:\n"
                            "    def __init__(self, name):\n"
                            "        self.name = name\n"
                            "\n"
                            "    def bark(self):\n"
                            "        print(f\"{self.name} says woof!\")\n"
                            "\n"
                            "d = Dog(\"Max\")\n"
                            "d.bark()\n"
                            "```\n\n"
                            "`self` refers to the current instance.\n\n"
                            "Key takeaway: classes group data (attributes) and behavior (methods) together."
                        ),
                        code_example=(
                            "class Car:\n"
                            "    def __init__(self, brand, year):\n"
                            "        self.brand = brand\n"
                            "        self.year = year\n"
                            "\n"
                            "    def info(self):\n"
                            "        return f\"{self.brand} ({self.year})\"\n"
                            "\n"
                            "c = Car(\"Toyota\", 2020)\n"
                            "print(c.info())\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What is a class?",
                        option_a="A variable",
                        option_b="A blueprint for objects",
                        option_c="A function",
                        option_d="A module",
                        correct_option="b",
                        explanation="A class defines the structure and behavior that objects (instances) will have.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What does self refer to?",
                        option_a="The class",
                        option_b="The current instance",
                        option_c="The parent class",
                        option_d="The module",
                        correct_option="b",
                        explanation="`self` points to the object instance calling the method.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="How do you create an object of class Car?",
                        option_a="Car.new()",
                        option_b="new Car()",
                        option_c="Car()",
                        option_d="create Car()",
                        correct_option="c",
                        explanation="In Python you call the class like a function: `Car(...)`.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Constructors",
                order=2,
                description="Initialize objects with __init__.",
                lessons=[
                    LessonSeed(
                        title="The __init__ Method",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "`__init__` is the constructor method called when you create an object.\n\n"
                            "```python\n"
                            "class Person:\n"
                            "    def __init__(self, name, age):\n"
                            "        self.name = name\n"
                            "        self.age = age\n"
                            "\n"
                            "p = Person(\"Amina\", 25)\n"
                            "```\n\n"
                            "You can also provide default values:\n\n"
                            "```python\n"
                            "class BankAccount:\n"
                            "    def __init__(self, owner, balance=0):\n"
                            "        self.owner = owner\n"
                            "        self.balance = balance\n"
                            "```\n\n"
                            "Key takeaway: constructors ensure your objects start in a valid state."
                        ),
                        code_example=(
                            "class BankAccount:\n"
                            "    def __init__(self, owner, balance=0):\n"
                            "        self.owner = owner\n"
                            "        self.balance = balance\n"
                            "\n"
                            "acc = BankAccount(\"Amina\", 100)\n"
                            "print(acc.owner, acc.balance)\n"
                        ),
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="When is __init__ called?",
                        option_a="When class is defined",
                        option_b="When object is created",
                        option_c="When method is called",
                        option_d="When program ends",
                        correct_option="b",
                        explanation="`__init__` is executed automatically right after an object is created.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What is the first parameter of __init__?",
                        option_a="this",
                        option_b="self",
                        option_c="init",
                        option_d="cls",
                        correct_option="b",
                        explanation="Instance methods receive the instance as the first parameter, by convention named `self`.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Encapsulation",
                order=3,
                description="Protect internal state using conventions and properties.",
                lessons=[
                    LessonSeed(
                        title="Private Variables and Methods",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "Encapsulation is about hiding internal details and exposing a safe interface.\n\n"
                            "Python uses conventions:\n"
                            "- `_name` means \"internal\" or protected by convention\n"
                            "- `__name` triggers name mangling (harder to access directly)\n\n"
                            "Using a property to control access:\n\n"
                            "```python\n"
                            "class BankAccount:\n"
                            "    def __init__(self, owner, balance=0):\n"
                            "        self.owner = owner\n"
                            "        self.__balance = balance\n"
                            "\n"
                            "    @property\n"
                            "    def balance(self):\n"
                            "        return self.__balance\n"
                            "\n"
                            "    def deposit(self, amount):\n"
                            "        if amount <= 0:\n"
                            "            raise ValueError(\"amount must be positive\")\n"
                            "        self.__balance += amount\n"
                            "```\n\n"
                            "Key takeaway: encapsulation prevents invalid updates and keeps objects consistent."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="How do you indicate a private variable in Python?",
                        option_a="private keyword",
                        option_b="Prefix with __",
                        option_c="Suffix with __",
                        option_d="Using const",
                        correct_option="b",
                        explanation="Double underscore triggers name mangling, commonly used to indicate private attributes.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What does @property do?",
                        option_a="Makes variable constant",
                        option_b="Allows method to be accessed like attribute",
                        option_c="Makes method private",
                        option_d="Deletes attribute",
                        correct_option="b",
                        explanation="A property lets you access a method using attribute syntax while keeping control logic inside.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Inheritance",
                order=4,
                description="Reuse and extend behavior with parent/child classes.",
                lessons=[
                    LessonSeed(
                        title="Parent and Child Classes",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "Inheritance lets you create a new class based on an existing class.\n\n"
                            "```python\n"
                            "class Animal:\n"
                            "    def __init__(self, name):\n"
                            "        self.name = name\n"
                            "\n"
                            "    def speak(self):\n"
                            "        return \"...\"\n"
                            "\n"
                            "class Dog(Animal):\n"
                            "    def speak(self):\n"
                            "        return \"woof\"\n"
                            "\n"
                            "d = Dog(\"Max\")\n"
                            "print(d.name, d.speak())\n"
                            "```\n\n"
                            "`super()` calls the parent implementation (often used in `__init__`).\n\n"
                            "Key takeaway: inheritance promotes code reuse and clean hierarchies."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What does inheritance promote?",
                        option_a="Code complexity",
                        option_b="Code reuse",
                        option_c="Code duplication",
                        option_d="Code deletion",
                        correct_option="b",
                        explanation="Inheritance lets you reuse parent behavior and override/extend where needed.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="How does a child call the parent's __init__?",
                        option_a="parent.__init__()",
                        option_b="super().__init__()",
                        option_c="base.__init__()",
                        option_d="self.parent()",
                        correct_option="b",
                        explanation="`super().__init__()` calls the base class constructor cleanly.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="What does isinstance(obj, Class) check?",
                        option_a="If class exists",
                        option_b="If obj is instance of Class",
                        option_c="If obj equals Class",
                        option_d="If Class is valid",
                        correct_option="b",
                        explanation="`isinstance` checks the runtime type relationship between an object and a class (including inheritance).",
                    ),
                ],
            ),
            ModuleSeed(
                title="Polymorphism",
                order=5,
                description="Same interface, different behavior through overriding and duck typing.",
                lessons=[
                    LessonSeed(
                        title="Method Overriding",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Polymorphism means \"many forms\" — the same method name can behave differently depending on the object.\n\n"
                            "Example with a base class and overrides:\n\n"
                            "```python\n"
                            "import math\n"
                            "\n"
                            "class Shape:\n"
                            "    def area(self):\n"
                            "        raise NotImplementedError\n"
                            "\n"
                            "class Circle(Shape):\n"
                            "    def __init__(self, r):\n"
                            "        self.r = r\n"
                            "    def area(self):\n"
                            "        return math.pi * self.r * self.r\n"
                            "\n"
                            "class Rectangle(Shape):\n"
                            "    def __init__(self, w, h):\n"
                            "        self.w = w\n"
                            "        self.h = h\n"
                            "    def area(self):\n"
                            "        return self.w * self.h\n"
                            "\n"
                            "shapes = [Circle(2), Rectangle(3, 4)]\n"
                            "for s in shapes:\n"
                            "    print(s.area())\n"
                            "```\n\n"
                            "Key takeaway: write code against a shared interface; objects supply the behavior."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Polymorphism means?",
                        option_a="One form",
                        option_b="Many forms",
                        option_c="No form",
                        option_d="Two forms",
                        correct_option="b",
                        explanation="Polymorphism refers to many forms of the same interface/method across types.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Method overriding happens in?",
                        option_a="Same class",
                        option_b="Child class",
                        option_c="Module",
                        option_d="Function",
                        correct_option="b",
                        explanation="A child class overrides a method by redefining it with the same name.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Abstraction",
                order=6,
                description="Define required methods with abstract base classes.",
                lessons=[
                    LessonSeed(
                        title="Abstract Classes",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Abstraction means focusing on essential behavior and hiding implementation details.\n\n"
                            "Python supports abstract classes using `abc`:\n\n"
                            "```python\n"
                            "from abc import ABC, abstractmethod\n"
                            "\n"
                            "class Payment(ABC):\n"
                            "    @abstractmethod\n"
                            "    def process_payment(self, amount):\n"
                            "        pass\n"
                            "\n"
                            "class CreditCard(Payment):\n"
                            "    def process_payment(self, amount):\n"
                            "        return f\"Charged {amount} via credit card\"\n"
                            "```\n\n"
                            "Abstract classes can’t be instantiated until all abstract methods are implemented.\n\n"
                            "Key takeaway: abstraction ensures a consistent interface across implementations."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Can you create an instance of an abstract class?",
                        option_a="Yes",
                        option_b="No",
                        option_c="Only with super()",
                        option_d="Only in main",
                        correct_option="b",
                        explanation="Abstract classes cannot be instantiated until abstract methods are implemented.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Which module provides ABC?",
                        option_a="abstract",
                        option_b="abc",
                        option_c="abs",
                        option_d="base",
                        correct_option="b",
                        explanation="Python’s `abc` module provides `ABC` and `abstractmethod`.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Project",
                order=7,
                description="Apply OOP concepts by building a banking CLI.",
                lessons=[
                    LessonSeed(
                        title="Banking System Project",
                        duration_minutes=30,
                        order=1,
                        content=(
                            "You’ll build a small banking system using OOP.\n\n"
                            "Design:\n"
                            "- `BankAccount` base class with deposit/withdraw/check_balance\n"
                            "- `SavingsAccount` adds interest calculation\n"
                            "- `CurrentAccount` adds overdraft limit\n"
                            "- `Bank` class manages accounts (create, find, list)\n\n"
                            "A condensed but complete example:\n\n"
                            "```python\n"
                            "class BankAccount:\n"
                            "    def __init__(self, owner, balance=0):\n"
                            "        self.owner = owner\n"
                            "        self.__balance = balance\n"
                            "\n"
                            "    @property\n"
                            "    def balance(self):\n"
                            "        return self.__balance\n"
                            "\n"
                            "    def deposit(self, amount):\n"
                            "        if amount <= 0:\n"
                            "            raise ValueError(\"amount must be positive\")\n"
                            "        self.__balance += amount\n"
                            "\n"
                            "    def withdraw(self, amount):\n"
                            "        if amount <= 0:\n"
                            "            raise ValueError(\"amount must be positive\")\n"
                            "        if amount > self.__balance:\n"
                            "            raise ValueError(\"insufficient funds\")\n"
                            "        self.__balance -= amount\n"
                            "\n"
                            "class SavingsAccount(BankAccount):\n"
                            "    def apply_interest(self, rate):\n"
                            "        self.deposit(self.balance * rate)\n"
                            "\n"
                            "class CurrentAccount(BankAccount):\n"
                            "    def __init__(self, owner, balance=0, overdraft=0):\n"
                            "        super().__init__(owner, balance)\n"
                            "        self.overdraft = overdraft\n"
                            "\n"
                            "    def withdraw(self, amount):\n"
                            "        if amount > self.balance + self.overdraft:\n"
                            "            raise ValueError(\"overdraft limit exceeded\")\n"
                            "        # allow withdrawal beyond balance up to overdraft\n"
                            "        super().deposit(-amount)\n"
                            "\n"
                            "class Bank:\n"
                            "    def __init__(self):\n"
                            "        self.accounts = {}\n"
                            "\n"
                            "    def add_account(self, account):\n"
                            "        self.accounts[account.owner] = account\n"
                            "\n"
                            "    def get(self, owner):\n"
                            "        return self.accounts.get(owner)\n"
                            "```\n\n"
                            "Key takeaway: OOP helps model real-world systems with clear responsibilities."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Which OOP concept is used when SavingsAccount extends BankAccount?",
                        option_a="Encapsulation",
                        option_b="Polymorphism",
                        option_c="Inheritance",
                        option_d="Abstraction",
                        correct_option="c",
                        explanation="Extending a base class is inheritance.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Why is balance a private attribute?",
                        option_a="Performance",
                        option_b="Encapsulation and security",
                        option_c="Inheritance requirement",
                        option_d="Python requirement",
                        correct_option="b",
                        explanation="Private attributes protect internal state from invalid changes and enforce rules via methods.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="What design pattern does the Bank class follow?",
                        option_a="Singleton",
                        option_b="Factory",
                        option_c="Manager/Controller",
                        option_d="Observer",
                        correct_option="c",
                        explanation="The Bank class coordinates and manages a collection of accounts, acting like a controller/manager.",
                    ),
                ],
            ),
        ],
    )


def _dsa_python() -> CourseSeed:
    return CourseSeed(
        title="Data Structures and Algorithms",
        slug="dsa-python",
        description=(
            "Build algorithmic thinking: time complexity, searching, sorting, stacks/queues, linked lists, trees, graphs, and practice problems. "
            "Learn not just how to code solutions, but how to analyze them."
        ),
        difficulty="advanced",
        color_hex="#F44336",
        icon="dsa",
        estimated_hours=12,
        order=4,
        is_published=True,
        modules=[
            ModuleSeed(
                title="Complexity",
                order=1,
                description="Understand Big-O and why it matters.",
                lessons=[
                    LessonSeed(
                        title="Big-O Basics",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "Time complexity describes how runtime grows as input size (n) increases.\n\n"
                            "Common complexities:\n"
                            "- O(1): constant time\n"
                            "- O(n): linear\n"
                            "- O(n^2): quadratic\n"
                            "- O(log n): logarithmic\n"
                            "- O(n log n): typical for efficient sorting\n\n"
                            "Examples:\n\n"
                            "```python\n"
                            "# O(1)\n"
                            "x = nums[0]\n"
                            "\n"
                            "# O(n)\n"
                            "for v in nums:\n"
                            "    print(v)\n"
                            "\n"
                            "# O(n^2)\n"
                            "for i in range(n):\n"
                            "    for j in range(n):\n"
                            "        pass\n"
                            "```\n\n"
                            "Space complexity measures extra memory used.\n\n"
                            "Key takeaway: Big-O helps you choose solutions that scale."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What is the time complexity of accessing an element in a list by index?",
                        option_a="O(n)",
                        option_b="O(1)",
                        option_c="O(log n)",
                        option_d="O(n^2)",
                        correct_option="b",
                        explanation="Index access in a Python list is constant time because it's backed by an array.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="A nested for loop over the same list of size n is typically?",
                        option_a="O(n)",
                        option_b="O(log n)",
                        option_c="O(n^2)",
                        option_d="O(1)",
                        correct_option="c",
                        explanation="Two loops each running n times multiply to n * n = n^2.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Arrays and Lists",
                order=2,
                description="Python lists as dynamic arrays and common patterns.",
                lessons=[
                    LessonSeed(
                        title="Array Operations",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "Python lists behave like dynamic arrays.\n\n"
                            "Operation costs (typical):\n"
                            "- append at end: O(1) amortized\n"
                            "- insert at start: O(n) (shift elements)\n"
                            "- search by value: O(n)\n\n"
                            "Two-pointer idea (common interview pattern):\n\n"
                            "```python\n"
                            "nums = [1, 2, 3, 4, 5]\n"
                            "l, r = 0, len(nums) - 1\n"
                            "while l < r:\n"
                            "    nums[l], nums[r] = nums[r], nums[l]\n"
                            "    l += 1\n"
                            "    r -= 1\n"
                            "print(nums)\n"
                            "```\n\n"
                            "Key takeaway: understand costs; the same code can behave very differently at scale."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What is the time complexity of list.append()?",
                        option_a="O(n)",
                        option_b="O(1) amortized",
                        option_c="O(log n)",
                        option_d="O(n^2)",
                        correct_option="b",
                        explanation="Appending is usually O(1), but occasionally resizes the underlying array; averaged it's amortized O(1).",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Inserting at the beginning of a Python list is?",
                        option_a="O(1)",
                        option_b="O(log n)",
                        option_c="O(n)",
                        option_d="O(n^2)",
                        correct_option="c",
                        explanation="All elements must shift right by one, which takes linear time.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Searching",
                order=3,
                description="Linear and binary search.",
                lessons=[
                    LessonSeed(
                        title="Linear Search",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Linear search checks elements one by one until it finds the target.\n\n"
                            "Time complexity: O(n)\n\n"
                            "Implementation returning index or -1:\n\n"
                            "```python\n"
                            "def linear_search(nums, target):\n"
                            "    for i, v in enumerate(nums):\n"
                            "        if v == target:\n"
                            "            return i\n"
                            "    return -1\n"
                            "```\n\n"
                            "Use linear search when data is unsorted or small.\n\n"
                            "Key takeaway: simple and reliable, but can be slow for large lists."
                        ),
                        code_example=None,
                    ),
                    LessonSeed(
                        title="Binary Search",
                        duration_minutes=18,
                        order=2,
                        content=(
                            "Binary search works on **sorted** data and repeatedly halves the search range.\n\n"
                            "Time complexity: O(log n)\n\n"
                            "Iterative binary search:\n\n"
                            "```python\n"
                            "def binary_search(nums, target):\n"
                            "    low, high = 0, len(nums) - 1\n"
                            "    while low <= high:\n"
                            "        mid = (low + high) // 2\n"
                            "        if nums[mid] == target:\n"
                            "            return mid\n"
                            "        if target < nums[mid]:\n"
                            "            high = mid - 1\n"
                            "        else:\n"
                            "            low = mid + 1\n"
                            "    return -1\n"
                            "```\n\n"
                            "Key takeaway: binary search is fast, but only works correctly when the list is sorted."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Binary search requires?",
                        option_a="Linked list",
                        option_b="Sorted array",
                        option_c="Stack",
                        option_d="Queue",
                        correct_option="b",
                        explanation="Binary search depends on ordering so it can discard half the search space each step.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Time complexity of binary search?",
                        option_a="O(n)",
                        option_b="O(n^2)",
                        option_c="O(log n)",
                        option_d="O(1)",
                        correct_option="c",
                        explanation="Each step halves the remaining range, leading to logarithmic time.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="In binary search, if target > mid element, where do you search?",
                        option_a="Left half",
                        option_b="Right half",
                        option_c="Both halves",
                        option_d="Start over",
                        correct_option="b",
                        explanation="If target is greater than nums[mid], it can only be in the right half of a sorted list.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Sorting",
                order=4,
                description="Bubble sort, selection sort, and merge sort.",
                lessons=[
                    LessonSeed(
                        title="Bubble Sort",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Bubble sort repeatedly swaps adjacent out-of-order elements.\n\n"
                            "Time complexity: O(n^2)\n\n"
                            "Optimized version with a swapped flag:\n\n"
                            "```python\n"
                            "def bubble_sort(a):\n"
                            "    n = len(a)\n"
                            "    for i in range(n):\n"
                            "        swapped = False\n"
                            "        for j in range(0, n - i - 1):\n"
                            "            if a[j] > a[j + 1]:\n"
                            "                a[j], a[j + 1] = a[j + 1], a[j]\n"
                            "                swapped = True\n"
                            "        if not swapped:\n"
                            "            break\n"
                            "    return a\n"
                            "```\n\n"
                            "Key takeaway: bubble sort is easy to learn, but not efficient for large datasets."
                        ),
                        code_example=None,
                    ),
                    LessonSeed(
                        title="Selection Sort",
                        duration_minutes=15,
                        order=2,
                        content=(
                            "Selection sort selects the smallest element from the unsorted portion and swaps it into place.\n\n"
                            "Time complexity: O(n^2)\n\n"
                            "```python\n"
                            "def selection_sort(a):\n"
                            "    n = len(a)\n"
                            "    for i in range(n):\n"
                            "        min_idx = i\n"
                            "        for j in range(i + 1, n):\n"
                            "            if a[j] < a[min_idx]:\n"
                            "                min_idx = j\n"
                            "        a[i], a[min_idx] = a[min_idx], a[i]\n"
                            "    return a\n"
                            "```\n\n"
                            "Key takeaway: simple and consistent, but still quadratic time."
                        ),
                        code_example=None,
                    ),
                    LessonSeed(
                        title="Introduction to Merge Sort",
                        duration_minutes=20,
                        order=3,
                        content=(
                            "Merge sort uses divide-and-conquer:\n"
                            "1) Split the list into halves\n"
                            "2) Recursively sort each half\n"
                            "3) Merge two sorted halves\n\n"
                            "Time complexity: O(n log n)\n"
                            "Space complexity: O(n)\n\n"
                            "```python\n"
                            "def merge_sort(a):\n"
                            "    if len(a) <= 1:\n"
                            "        return a\n"
                            "    mid = len(a) // 2\n"
                            "    left = merge_sort(a[:mid])\n"
                            "    right = merge_sort(a[mid:])\n"
                            "    return merge(left, right)\n"
                            "\n"
                            "def merge(left, right):\n"
                            "    out = []\n"
                            "    i = j = 0\n"
                            "    while i < len(left) and j < len(right):\n"
                            "        if left[i] <= right[j]:\n"
                            "            out.append(left[i])\n"
                            "            i += 1\n"
                            "        else:\n"
                            "            out.append(right[j])\n"
                            "            j += 1\n"
                            "    out.extend(left[i:])\n"
                            "    out.extend(right[j:])\n"
                            "    return out\n"
                            "```\n\n"
                            "Key takeaway: merge sort is much faster than quadratic sorts on large lists."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Which sorting algorithm has O(n log n) average time?",
                        option_a="Bubble Sort",
                        option_b="Selection Sort",
                        option_c="Merge Sort",
                        option_d="All of them",
                        correct_option="c",
                        explanation="Merge sort runs in O(n log n) time for all cases.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Bubble sort is a what type of sort?",
                        option_a="Divide and conquer",
                        option_b="Comparison-based with adjacent swaps",
                        option_c="Hash-based",
                        option_d="Recursive only",
                        correct_option="b",
                        explanation="Bubble sort compares adjacent pairs and swaps them to move larger values right.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="What is the space complexity of merge sort?",
                        option_a="O(1)",
                        option_b="O(log n)",
                        option_c="O(n)",
                        option_d="O(n^2)",
                        correct_option="c",
                        explanation="Merging requires extra space proportional to the number of elements.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Stack and Queue",
                order=5,
                description="Classic linear data structures and their use cases.",
                lessons=[
                    LessonSeed(
                        title="Stack",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "A stack follows LIFO: Last In, First Out.\n\n"
                            "Operations:\n"
                            "- push (add)\n"
                            "- pop (remove)\n"
                            "- peek (top element)\n\n"
                            "Implementation using list:\n\n"
                            "```python\n"
                            "class Stack:\n"
                            "    def __init__(self):\n"
                            "        self._data = []\n"
                            "    def push(self, x):\n"
                            "        self._data.append(x)\n"
                            "    def pop(self):\n"
                            "        return self._data.pop()\n"
                            "    def peek(self):\n"
                            "        return self._data[-1] if self._data else None\n"
                            "    def is_empty(self):\n"
                            "        return not self._data\n"
                            "```\n\n"
                            "Balanced parentheses checker:\n\n"
                            "```python\n"
                            "def is_balanced(s):\n"
                            "    pairs = {')': '(', ']': '[', '}': '{'}\n"
                            "    st = []\n"
                            "    for ch in s:\n"
                            "        if ch in '([{':\n"
                            "            st.append(ch)\n"
                            "        elif ch in pairs:\n"
                            "            if not st or st.pop() != pairs[ch]:\n"
                            "                return False\n"
                            "    return not st\n"
                            "```\n\n"
                            "Key takeaway: stacks model “undo” behavior and nested structure validation."
                        ),
                        code_example=None,
                    ),
                    LessonSeed(
                        title="Queue",
                        duration_minutes=15,
                        order=2,
                        content=(
                            "A queue follows FIFO: First In, First Out.\n\n"
                            "Use `collections.deque` for efficient enqueue/dequeue:\n\n"
                            "```python\n"
                            "from collections import deque\n"
                            "\n"
                            "class Queue:\n"
                            "    def __init__(self):\n"
                            "        self._d = deque()\n"
                            "    def enqueue(self, x):\n"
                            "        self._d.append(x)\n"
                            "    def dequeue(self):\n"
                            "        return self._d.popleft()\n"
                            "    def peek(self):\n"
                            "        return self._d[0] if self._d else None\n"
                            "    def is_empty(self):\n"
                            "        return not self._d\n"
                            "```\n\n"
                            "Key takeaway: queues are essential in BFS and scheduling."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Stack follows which principle?",
                        option_a="FIFO",
                        option_b="LIFO",
                        option_c="LILO",
                        option_d="FILO",
                        correct_option="b",
                        explanation="Stacks remove the most recently added item first (Last In, First Out).",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Which Python module provides an efficient deque?",
                        option_a="queue",
                        option_b="collections",
                        option_c="array",
                        option_d="stack",
                        correct_option="b",
                        explanation="`collections.deque` supports O(1) append and popleft operations.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Linked List",
                order=6,
                description="Nodes and pointers instead of contiguous arrays.",
                lessons=[
                    LessonSeed(
                        title="Linked List Basics",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "A linked list is a chain of nodes. Each node stores data and a reference to the next node.\n\n"
                            "Singly linked list example:\n\n"
                            "```python\n"
                            "class Node:\n"
                            "    def __init__(self, data, next=None):\n"
                            "        self.data = data\n"
                            "        self.next = next\n"
                            "\n"
                            "class LinkedList:\n"
                            "    def __init__(self):\n"
                            "        self.head = None\n"
                            "\n"
                            "    def push_front(self, data):\n"
                            "        self.head = Node(data, self.head)\n"
                            "\n"
                            "    def to_list(self):\n"
                            "        out = []\n"
                            "        cur = self.head\n"
                            "        while cur:\n"
                            "            out.append(cur.data)\n"
                            "            cur = cur.next\n"
                            "        return out\n"
                            "```\n\n"
                            "Pros: fast insertions (no shifting), dynamic size.\n"
                            "Cons: no random access; traversal is O(n).\n\n"
                            "Key takeaway: linked lists trade index access for pointer-based flexibility."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Each element in a linked list is called?",
                        option_a="Index",
                        option_b="Node",
                        option_c="Block",
                        option_d="Cell",
                        correct_option="b",
                        explanation="Linked lists are built from nodes connected by references.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Accessing the nth element in a linked list is?",
                        option_a="O(1)",
                        option_b="O(log n)",
                        option_c="O(n)",
                        option_d="O(n^2)",
                        correct_option="c",
                        explanation="You must traverse from the head node to reach the nth node, which is linear time.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Trees",
                order=7,
                description="Binary trees, BSTs, and traversals.",
                lessons=[
                    LessonSeed(
                        title="Binary Tree",
                        duration_minutes=22,
                        order=1,
                        content=(
                            "Trees are hierarchical structures with a root and children.\n\n"
                            "Binary tree: each node has at most two children.\n"
                            "Binary Search Tree (BST): left < node < right.\n\n"
                            "BST node and insert:\n\n"
                            "```python\n"
                            "class Node:\n"
                            "    def __init__(self, val):\n"
                            "        self.val = val\n"
                            "        self.left = None\n"
                            "        self.right = None\n"
                            "\n"
                            "def insert(root, val):\n"
                            "    if root is None:\n"
                            "        return Node(val)\n"
                            "    if val < root.val:\n"
                            "        root.left = insert(root.left, val)\n"
                            "    else:\n"
                            "        root.right = insert(root.right, val)\n"
                            "    return root\n"
                            "```\n\n"
                            "Inorder traversal of a BST yields sorted values.\n\n"
                            "Key takeaway: trees model hierarchical data and enable efficient searching when balanced."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="In a BST, left child is?",
                        option_a="Greater than parent",
                        option_b="Less than parent",
                        option_c="Equal to parent",
                        option_d="Random",
                        correct_option="b",
                        explanation="BST property: left subtree values are less than the node’s value.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Inorder traversal of a BST gives?",
                        option_a="Random order",
                        option_b="Sorted order",
                        option_c="Reverse order",
                        option_d="Level order",
                        correct_option="b",
                        explanation="Inorder traversal visits left, node, right — which yields sorted values in a BST.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Graphs",
                order=8,
                description="BFS and DFS traversals using adjacency lists.",
                lessons=[
                    LessonSeed(
                        title="BFS and DFS",
                        duration_minutes=25,
                        order=1,
                        content=(
                            "Graphs model relationships between nodes (vertices) connected by edges.\n\n"
                            "Represent a graph with an adjacency list:\n\n"
                            "```python\n"
                            "graph = {\n"
                            "  \"A\": [\"B\", \"C\"],\n"
                            "  \"B\": [\"D\"],\n"
                            "  \"C\": [\"D\"],\n"
                            "  \"D\": []\n"
                            "}\n"
                            "```\n\n"
                            "BFS (Breadth-First Search) uses a queue and explores level by level:\n\n"
                            "```python\n"
                            "from collections import deque\n"
                            "\n"
                            "def bfs(graph, start):\n"
                            "    q = deque([start])\n"
                            "    seen = {start}\n"
                            "    order = []\n"
                            "    while q:\n"
                            "        node = q.popleft()\n"
                            "        order.append(node)\n"
                            "        for nxt in graph[node]:\n"
                            "            if nxt not in seen:\n"
                            "                seen.add(nxt)\n"
                            "                q.append(nxt)\n"
                            "    return order\n"
                            "```\n\n"
                            "DFS (Depth-First Search) uses a stack or recursion to go deep:\n\n"
                            "```python\n"
                            "def dfs(graph, start):\n"
                            "    st = [start]\n"
                            "    seen = {start}\n"
                            "    order = []\n"
                            "    while st:\n"
                            "        node = st.pop()\n"
                            "        order.append(node)\n"
                            "        for nxt in reversed(graph[node]):\n"
                            "            if nxt not in seen:\n"
                            "                seen.add(nxt)\n"
                            "                st.append(nxt)\n"
                            "    return order\n"
                            "```\n\n"
                            "Key takeaway: BFS is great for shortest paths in unweighted graphs; DFS is great for exploring and backtracking."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="BFS uses which data structure?",
                        option_a="Stack",
                        option_b="Queue",
                        option_c="Heap",
                        option_d="Tree",
                        correct_option="b",
                        explanation="BFS explores neighbors level by level using a queue.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="DFS uses which data structure?",
                        option_a="Queue",
                        option_b="Heap",
                        option_c="Stack",
                        option_d="Array",
                        correct_option="c",
                        explanation="DFS uses a stack (explicitly or via recursion) to go deep first.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="An adjacency list represents a graph using?",
                        option_a="Matrix",
                        option_b="Dictionary/List of lists",
                        option_c="Tree",
                        option_d="Linked List",
                        correct_option="b",
                        explanation="Adjacency lists map each vertex to a list of neighbors.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Practice Problems",
                order=9,
                description="Apply concepts to typical interview-style problems.",
                lessons=[
                    LessonSeed(
                        title="DSA Exercises",
                        duration_minutes=30,
                        order=1,
                        content=(
                            "Practice problems with solutions and complexity:\n\n"
                            "1) Reverse a string using a stack\n\n"
                            "```python\n"
                            "def reverse_string(s):\n"
                            "    st = list(s)\n"
                            "    out = []\n"
                            "    while st:\n"
                            "        out.append(st.pop())\n"
                            "    return \"\".join(out)\n"
                            "```\n"
                            "Time: O(n), Space: O(n)\n\n"
                            "2) Two Sum (find pair equals target)\n\n"
                            "```python\n"
                            "def two_sum(nums, target):\n"
                            "    seen = {}\n"
                            "    for i, v in enumerate(nums):\n"
                            "        need = target - v\n"
                            "        if need in seen:\n"
                            "            return seen[need], i\n"
                            "        seen[v] = i\n"
                            "    return None\n"
                            "```\n"
                            "Time: O(n), Space: O(n)\n\n"
                            "3) Palindrome check\n\n"
                            "```python\n"
                            "def is_pal(s):\n"
                            "    s = \"\".join(ch.lower() for ch in s if ch.isalnum())\n"
                            "    return s == s[::-1]\n"
                            "```\n"
                            "Time: O(n)\n\n"
                            "4) Maximum element in a binary tree (DFS)\n\n"
                            "```python\n"
                            "def tree_max(node):\n"
                            "    if node is None:\n"
                            "        return float(\"-inf\")\n"
                            "    return max(node.val, tree_max(node.left), tree_max(node.right))\n"
                            "```\n\n"
                            "5) Detect cycle in a linked list (concept: Floyd's tortoise-hare)\n"
                            "- Move one pointer by 1 step and another by 2 steps. If they meet, there is a cycle.\n\n"
                            "Key takeaway: focus on patterns: stacks, hash maps, two pointers, DFS/BFS."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Two Sum problem can be solved in O(n) using?",
                        option_a="Sorting",
                        option_b="Hash map/dictionary",
                        option_c="Binary search",
                        option_d="Brute force",
                        correct_option="b",
                        explanation="A hash map tracks seen values and allows O(1) average lookups, giving O(n) total time.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="To reverse a string using a stack, you?",
                        option_a="Push all chars then pop all",
                        option_b="Pop then push",
                        option_c="Use recursion only",
                        option_d="Use sorting",
                        correct_option="a",
                        explanation="A stack reverses order because it pops the last pushed character first.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="A palindrome reads the same?",
                        option_a="Top to bottom",
                        option_b="Forward and backward",
                        option_c="Left to right only",
                        option_d="Diagonally",
                        correct_option="b",
                        explanation="A palindrome is unchanged when reversed.",
                    ),
                ],
            ),
        ],
    )


def _guided_project() -> CourseSeed:
    return CourseSeed(
        title="Guided Project - Smart Land Rental System",
        slug="guided-project",
        description=(
            "A capstone guided project: design classes, manage data with lists/dicts, implement searching and sorting, add rental rules, "
            "persist data to JSON files, and build a menu-driven CLI."
        ),
        difficulty="advanced",
        color_hex="#9C27B0",
        icon="project",
        estimated_hours=10,
        order=5,
        is_published=True,
        modules=[
            ModuleSeed(
                title="Project Overview",
                order=1,
                description="Understand the problem and the full feature set.",
                lessons=[
                    LessonSeed(
                        title="Project Overview and Requirements",
                        duration_minutes=15,
                        order=1,
                        content=(
                            "Smart Land Rental System: manage land plots for rental.\n\n"
                            "Problem statement:\n"
                            "You want a simple program that tracks lands and allows customers to rent/return them.\n\n"
                            "Features:\n"
                            "- Add land\n"
                            "- List all lands\n"
                            "- Search by location/size\n"
                            "- Sort by price/size/location\n"
                            "- Rent and return land\n"
                            "- Save and load data from files (JSON)\n\n"
                            "Concepts you’ll apply:\n"
                            "- OOP for modeling Land and RentalSystem\n"
                            "- Data structures (lists, dicts)\n"
                            "- Searching and sorting\n"
                            "- File handling with JSON\n\n"
                            "Key takeaway: we’re building a complete CLI tool by combining multiple Python fundamentals."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What programming paradigm will this project primarily use?",
                        option_a="Functional",
                        option_b="Procedural",
                        option_c="Object-Oriented",
                        option_d="Logic",
                        correct_option="c",
                        explanation="We model land plots and the system using classes and objects, which is OOP.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What is the main purpose of the project?",
                        option_a="Web development",
                        option_b="Land rental management",
                        option_c="Game development",
                        option_d="Data analysis",
                        correct_option="b",
                        explanation="The project is a land rental management tool for adding, searching, sorting, renting, and saving land plots.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Class Design",
                order=2,
                description="Design core classes and methods.",
                lessons=[
                    LessonSeed(
                        title="OOP Class Design",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "We’ll design two key classes:\n\n"
                            "1) `Land`\n"
                            "- id\n"
                            "- location\n"
                            "- size_acres\n"
                            "- price_per_month\n"
                            "- is_available\n"
                            "- renter_name\n\n"
                            "2) `RentalSystem`\n"
                            "- holds a list of lands\n"
                            "- methods for add/search/sort/rent/return/save/load\n\n"
                            "A practical `Land` class:\n\n"
                            "```python\n"
                            "class Land:\n"
                            "    def __init__(self, id, location, size_acres, price_per_month, is_available=True, renter_name=\"\"):\n"
                            "        self.id = id\n"
                            "        self.location = location\n"
                            "        self.size_acres = float(size_acres)\n"
                            "        self.price_per_month = float(price_per_month)\n"
                            "        self.is_available = bool(is_available)\n"
                            "        self.renter_name = renter_name\n"
                            "\n"
                            "    def __str__(self):\n"
                            "        status = \"Available\" if self.is_available else f\"Rented to {self.renter_name}\"\n"
                            "        return f\"#{self.id} | {self.location} | {self.size_acres} acres | ${self.price_per_month}/mo | {status}\"\n"
                            "\n"
                            "    def to_dict(self):\n"
                            "        return {\n"
                            "            \"id\": self.id,\n"
                            "            \"location\": self.location,\n"
                            "            \"size_acres\": self.size_acres,\n"
                            "            \"price_per_month\": self.price_per_month,\n"
                            "            \"is_available\": self.is_available,\n"
                            "            \"renter_name\": self.renter_name,\n"
                            "        }\n"
                            "```\n\n"
                            "Key takeaway: define data + behavior together, and add `to_dict()` for easy JSON saving."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Why do we create a to_dict method?",
                        option_a="For printing",
                        option_b="For file serialization",
                        option_c="For inheritance",
                        option_d="For deletion",
                        correct_option="b",
                        explanation="JSON can’t serialize custom objects directly, so we convert them to dictionaries.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="The RentalSystem class follows which pattern?",
                        option_a="Singleton",
                        option_b="Observer",
                        option_c="Manager/Controller",
                        option_d="Factory",
                        correct_option="c",
                        explanation="RentalSystem coordinates actions and manages a collection of Land objects.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Data Handling",
                order=3,
                description="Manage collections with lists and dictionaries.",
                lessons=[
                    LessonSeed(
                        title="Lists and Dictionaries for Data",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "We’ll store all `Land` objects in a list:\n\n"
                            "```python\n"
                            "self.lands = []\n"
                            "```\n\n"
                            "Filtering lands using list comprehensions:\n\n"
                            "```python\n"
                            "available = [land for land in self.lands if land.is_available]\n"
                            "```\n\n"
                            "Adding and removing items:\n\n"
                            "```python\n"
                            "def add_land(self, land):\n"
                            "    self.lands.append(land)\n"
                            "\n"
                            "def remove_land(self, land_id):\n"
                            "    self.lands = [l for l in self.lands if l.id != land_id]\n"
                            "```\n\n"
                            "Key takeaway: lists hold your objects; dicts are great for JSON and fast lookup patterns."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="What data structure holds all Land objects?",
                        option_a="Dictionary",
                        option_b="List",
                        option_c="Tuple",
                        option_d="Set",
                        correct_option="b",
                        explanation="We store Land objects in a list for ordering and iteration.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="List comprehension is used for?",
                        option_a="Sorting",
                        option_b="Filtering and transforming",
                        option_c="Deleting",
                        option_d="Printing",
                        correct_option="b",
                        explanation="List comprehensions build new lists by filtering and/or transforming elements.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Searching System",
                order=4,
                description="Search by location, size, and price ranges.",
                lessons=[
                    LessonSeed(
                        title="Implementing Search",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "We’ll implement searching using simple filtering.\n\n"
                            "Location search (case-insensitive substring match):\n\n"
                            "```python\n"
                            "def search_by_location(self, query):\n"
                            "    q = query.strip().lower()\n"
                            "    return [l for l in self.lands if q in l.location.lower()]\n"
                            "```\n\n"
                            "Search by size and price ranges:\n\n"
                            "```python\n"
                            "def search_by_size_range(self, min_size, max_size):\n"
                            "    return [l for l in self.lands if min_size <= l.size_acres <= max_size]\n"
                            "```\n\n"
                            "Also consider filtering available lands:\n\n"
                            "```python\n"
                            "results = [l for l in results if l.is_available]\n"
                            "```\n\n"
                            "Key takeaway: searching is often just careful filtering with clear conditions."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="String matching for location search uses?",
                        option_a="==",
                        option_b="in keyword or lower() comparison",
                        option_c="Regular expressions",
                        option_d="Hash tables",
                        correct_option="b",
                        explanation="A simple and effective approach is to compare lowercase strings using `in`.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Filtering by range requires checking?",
                        option_a="Equality only",
                        option_b="Min and max bounds",
                        option_c="Type only",
                        option_d="Length",
                        correct_option="b",
                        explanation="A range filter checks `min_value <= x <= max_value`.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Sorting System",
                order=5,
                description="Sort by price, size, and location.",
                lessons=[
                    LessonSeed(
                        title="Implementing Sorting",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "Sorting changes the order of results, which helps users compare options.\n\n"
                            "Use `sorted()` with a `key` function:\n\n"
                            "```python\n"
                            "def sort_by_price(self, descending=False):\n"
                            "    return sorted(self.lands, key=lambda l: l.price_per_month, reverse=descending)\n"
                            "```\n\n"
                            "Sort by size:\n\n"
                            "```python\n"
                            "sorted(self.lands, key=lambda l: l.size_acres)\n"
                            "```\n\n"
                            "Sort by location alphabetically:\n\n"
                            "```python\n"
                            "sorted(self.lands, key=lambda l: l.location.lower())\n"
                            "```\n\n"
                            "Key takeaway: `sorted(..., key=...)` is one of the most useful tools in everyday Python."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="The key parameter in sorted() takes?",
                        option_a="A value",
                        option_b="A function",
                        option_c="A string",
                        option_d="An index",
                        correct_option="b",
                        explanation="`key` takes a function that returns the value to sort by for each item.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="To sort in descending order, use?",
                        option_a="reverse=True",
                        option_b="desc=True",
                        option_c="order=\"desc\"",
                        option_d="ascending=False",
                        correct_option="a",
                        explanation="`sorted(..., reverse=True)` sorts from largest to smallest.",
                    ),
                ],
            ),
            ModuleSeed(
                title="Rental Logic",
                order=6,
                description="Business rules for renting and returning land.",
                lessons=[
                    LessonSeed(
                        title="Rental Business Logic",
                        duration_minutes=20,
                        order=1,
                        content=(
                            "Rental rules ensure data stays consistent.\n\n"
                            "Renting:\n"
                            "- Only allow if land is available\n"
                            "- Set renter name\n"
                            "- Mark land unavailable\n\n"
                            "Returning:\n"
                            "- Clear renter name\n"
                            "- Mark land available\n\n"
                            "Example:\n\n"
                            "```python\n"
                            "def rent_land(self, land_id, renter_name):\n"
                            "    land = self.find_by_id(land_id)\n"
                            "    if land is None:\n"
                            "        raise ValueError(\"Land not found\")\n"
                            "    if not land.is_available:\n"
                            "        raise ValueError(\"Land is already rented\")\n"
                            "    land.is_available = False\n"
                            "    land.renter_name = renter_name\n"
                            "\n"
                            "def return_land(self, land_id):\n"
                            "    land = self.find_by_id(land_id)\n"
                            "    if land is None:\n"
                            "        raise ValueError(\"Land not found\")\n"
                            "    land.is_available = True\n"
                            "    land.renter_name = \"\"\n"
                            "```\n\n"
                            "Cost calculation:\n\n"
                            "```python\n"
                            "def cost_for_months(land, months):\n"
                            "    return land.price_per_month * months\n"
                            "```\n\n"
                            "Key takeaway: validate first, then update state."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Before renting, what must be checked?",
                        option_a="Land size",
                        option_b="Land availability",
                        option_c="Land color",
                        option_d="Land age",
                        correct_option="b",
                        explanation="You must ensure the land is available; otherwise renting would overwrite existing rentals.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What happens to is_available when land is rented?",
                        option_a="Stays True",
                        option_b="Becomes False",
                        option_c="Becomes None",
                        option_d="Is deleted",
                        correct_option="b",
                        explanation="Rented land is not available, so `is_available` becomes False.",
                    ),
                ],
            ),
            ModuleSeed(
                title="File Handling",
                order=7,
                description="Save and load land data with JSON persistence.",
                lessons=[
                    LessonSeed(
                        title="Persistence with Files",
                        duration_minutes=18,
                        order=1,
                        content=(
                            "We’ll store land data in a JSON file.\n\n"
                            "Steps:\n"
                            "- Convert each Land object to a dictionary via `to_dict()`\n"
                            "- Save a list of dicts using `json.dump`\n"
                            "- On startup, load the file and reconstruct Land objects\n\n"
                            "Example:\n\n"
                            "```python\n"
                            "import json\n"
                            "import os\n"
                            "\n"
                            "def save_to_file(self, path):\n"
                            "    data = [l.to_dict() for l in self.lands]\n"
                            "    with open(path, \"w\", encoding=\"utf-8\") as f:\n"
                            "        json.dump(data, f, indent=2)\n"
                            "\n"
                            "def load_from_file(self, path):\n"
                            "    if not os.path.exists(path):\n"
                            "        self.lands = []\n"
                            "        return\n"
                            "    with open(path, \"r\", encoding=\"utf-8\") as f:\n"
                            "        data = json.load(f)\n"
                            "    self.lands = [Land(**d) for d in data]\n"
                            "```\n\n"
                            "Key takeaway: persistence turns a script into a real application."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="Why convert to dict before saving to JSON?",
                        option_a="JSON cannot store objects",
                        option_b="For speed",
                        option_c="For compression",
                        option_d="For encryption",
                        correct_option="a",
                        explanation="The JSON encoder can't serialize custom objects, but it can serialize basic types like dict/list/str/num.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="What error do we handle for first-time runs?",
                        option_a="ValueError",
                        option_b="TypeError",
                        option_c="FileNotFoundError",
                        option_d="KeyError",
                        correct_option="c",
                        explanation="When the JSON file doesn't exist yet, we handle missing file scenarios.",
                    ),
                ],
            ),
            ModuleSeed(
                title="CLI Interface",
                order=8,
                description="Build the full menu-driven program.",
                lessons=[
                    LessonSeed(
                        title="Building the CLI",
                        duration_minutes=25,
                        order=1,
                        content=(
                            "A CLI ties everything together: data, searching, sorting, rental logic, and file persistence.\n\n"
                            "Menu options:\n"
                            "1) Add Land\n"
                            "2) View All\n"
                            "3) Search\n"
                            "4) Sort\n"
                            "5) Rent Land\n"
                            "6) Return Land\n"
                            "7) Save and Exit\n\n"
                            "A strong pattern for CLIs:\n"
                            "- Use `while True` loop\n"
                            "- Validate inputs\n"
                            "- Keep each action in a method\n\n"
                            "Key takeaway: the CLI is just a loop + function calls + clean validation."
                        ),
                        code_example=None,
                    ),
                ],
                quiz=[
                    QuizSeed(
                        order=1,
                        question_text="The main loop of the CLI uses?",
                        option_a="for loop",
                        option_b="while True with break",
                        option_c="Recursion",
                        option_d="Threading",
                        correct_option="b",
                        explanation="Most menu CLIs use `while True` and `break` when the user chooses exit.",
                    ),
                    QuizSeed(
                        order=2,
                        question_text="Which concepts from previous courses were used?",
                        option_a="Only loops",
                        option_b="Only OOP",
                        option_c="OOP, data structures, file handling, searching, sorting",
                        option_d="Only file handling",
                        correct_option="c",
                        explanation="The project combines multiple skills: OOP + collections + algorithms + persistence.",
                    ),
                    QuizSeed(
                        order=3,
                        question_text="What makes this a complete project?",
                        option_a="It has a GUI",
                        option_b="It combines multiple programming concepts into a working system",
                        option_c="It uses a database",
                        option_d="It has a web interface",
                        correct_option="b",
                        explanation="A complete project integrates features and persistence into a usable program, even without a GUI.",
                    ),
                ],
            ),
        ],
    )


class Command(BaseCommand):
    help = "Seed all Guido courses, modules, lessons, and quiz questions."

    @transaction.atomic
    def handle(self, *args, **options):
        courses_seeded = 0
        modules_seeded = 0
        lessons_seeded = 0
        questions_seeded = 0

        for course_seed in _seed_data():
            course = _upsert_course(course_seed)
            courses_seeded += 1

            for module_seed in course_seed.modules:
                module = _upsert_module(course, module_seed)
                modules_seeded += 1

                for lesson_seed in module_seed.lessons:
                    _upsert_lesson(module, lesson_seed)
                    lessons_seeded += 1

                for quiz_seed in module_seed.quiz:
                    _upsert_quiz_question(module, quiz_seed)
                    questions_seeded += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Seeded {courses_seeded} courses, {modules_seeded} modules, {lessons_seeded} lessons, {questions_seeded} quiz questions."
            )
        )
