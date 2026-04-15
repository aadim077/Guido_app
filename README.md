# Guido Learning Platform

Guido is an MVP Python learning platform that pairs a Django REST API (JWT auth) with a Flutter mobile app.

Users can sign up / log in, browse and enroll in Python courses, complete lessons, take quizzes, and earn downloadable PDF certificates. The platform supports role-based routing (users go to the Learn dashboard, admins go to the Admin Dashboard).

## Features

- **Authentication**: JWT-based login/signup with role-based routing
- **Course System**: Browse available courses, view detailed curriculum (modules and lessons), and enroll
- **Interactive Lessons**: Read through lesson material with embedded code snippets
- **Quizzes**: Test your knowledge at the end of each module
- **Certificates**: Automatically earn and download a personalized PDF certificate upon completing a full course (all lessons and quizzes passed)
- **Profile & Progress**: Track your learning stats, earned certificates, and total points
- **Code Practice**: Solve 5 Python coding challenges directly in the app with a built-in code editor, real-time execution, and automated judging
- **Admin Dashboard**: View platform statistics (users, courses, enrollments, certificates, and code practice metrics)

## Tech Stack

- **Backend**: Django + Django REST Framework + ReportLab (for PDF generation)
- **Auth**: JWT (Simple JWT)
- **Database**: PostgreSQL
- **Frontend**: Flutter (Provider + Shared Preferences + open_filex + permission_handler)

## Prerequisites

- Python 3.x
- Flutter SDK
- PostgreSQL running locally

## Database Setup

Create a PostgreSQL database named `Guido`:

```bash
createdb -U postgres Guido
```

Database credentials used by the backend:

- **NAME**: Guido
- **USER**: postgres
- **PASSWORD**: admin123
- **HOST**: localhost
- **PORT**: 5432

## Backend Setup

From the repo root:

```bash
cd backend
python -m pip install -r requirements.txt
python manage.py makemigrations accounts courses
python manage.py migrate
python manage.py seed_users
python manage.py seed_courses
python manage.py seed_coding_questions
python manage.py runserver
```

### Test Credentials

- **Admin**: `admin@guido.com` / `admin123`
- **User**: `user@guido.com` / `user123`

### API Endpoints

All endpoints are under `/api/`.

- **POST** `/api/auth/signup/`
- **POST** `/api/auth/login/`
- **GET** `/api/auth/profile/` (JWT required)
- **GET** `/api/admin/dashboard/` (JWT + admin role required)
- **GET** `/api/courses/` (JWT required)
- **POST** `/api/courses/<id>/enroll/` (JWT required)
- **GET** `/api/lessons/<id>/` (JWT required)
- **POST** `/api/lessons/<id>/complete/` (JWT required)
- **GET** `/api/quizzes/module/<id>/` (JWT required)
- **POST** `/api/quizzes/module/<id>/submit/` (JWT required)
- **GET/POST** `/api/certificates/` (JWT required)
- **GET** `/api/progress/` (JWT required)
- **GET** `/api/code/questions/` (JWT required)
- **GET** `/api/code/questions/<id>/` (JWT required)
- **POST** `/api/code/run/` (JWT required)
- **POST** `/api/code/submit/` (JWT required)
- **GET** `/api/code/submissions/` (JWT required)

## Frontend Setup

```bash
cd guido_app
flutter pub get
flutter run
```

### Notes on Base URL

In `guido_app/lib/config/api_config.dart`:

- Android emulator uses `http://10.0.2.2:8000/api/`
- Flutter web / iOS simulator uses `http://localhost:8000/api/`
- Physical devices require the local IP address

## Folder Structure (high level)

```text
GG/
├── backend/
│   ├── accounts/
│   ├── courses/
│   ├── code_practice/
│   ├── guido_backend/
│   ├── manage.py
│   └── requirements.txt
├── guido_app/
│   ├── lib/
│   │   ├── config/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
└── README.md
```

## Code Practice Feature

The Code Practice tab lets users solve 5 Python coding challenges:

1. **Print Hello Guido** — simple print statement
2. **Sum of Two Numbers** — read input, compute sum
3. **Even or Odd** — conditional logic
4. **Maximum of Three Numbers** — find the largest value
5. **Reverse a String** — string manipulation

Flow: user writes Python code in the Flutter editor → code is sent to the Django backend → backend executes it with `subprocess.run(..., timeout=3)` → stdout/stderr captured → output compared against expected output for judging.

Basic safety checks block dangerous patterns (e.g., `os.system`, `subprocess`, `eval`).

> **Note:** This is an MVP implementation. The execution environment is not sandboxed. Do not expose to untrusted users without adding Docker-based isolation or a dedicated code runner.

To seed the coding questions:

```bash
python manage.py seed_coding_questions
```

## Local Notifications - Daily Study Reminders

- Feature: Daily reminder at user-selected time
- No backend required, fully local
- Packages: flutter_local_notifications, timezone
- Setup: no extra setup needed, auto-initializes on app start
- User flow:
  1. Open Profile tab
  2. Tap Settings
  3. Enable Daily Reminder
  4. Pick a time using time picker
  5. Notification is scheduled and fires every day at that time
  6. User can update time or disable reminder any time
- Android: requires android.permission.POST_NOTIFICATIONS on Android 13+
- iOS: permission prompt shown on first enable
- Web: not supported, handled gracefully
- Notification tap: opens the Home screen

