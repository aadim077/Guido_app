# Guido

Guido is a simple MVP that pairs a Django REST API (JWT auth) with a Flutter client.
Users can sign up / log in, and the app routes them based on their role:
regular users go to Home, admins go to the Admin Dashboard.

## Tech stack

- **Backend**: Django + Django REST Framework
- **Auth**: JWT (Simple JWT)
- **Database**: PostgreSQL
- **Frontend**: Flutter (Provider + Shared Preferences)

## Prerequisites

- Python 3.x
- Flutter SDK
- PostgreSQL running locally

## Database setup

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

## Backend setup

From the repo root:

```bash
cd backend
python -m pip install -r requirements.txt
python manage.py makemigrations accounts
python manage.py migrate
python manage.py seed_users
python manage.py runserver
```

### Test credentials

- **Admin**: `admin@guido.com` / `admin123`
- **User**: `user@guido.com` / `user123`

### API endpoints

All endpoints are under `/api/`.

- **POST** `/api/auth/signup/`
- **POST** `/api/auth/login/`
- **GET** `/api/auth/profile/` (JWT required)
- **GET** `/api/admin/dashboard/` (JWT + admin role required)

## Frontend setup

```bash
cd guido_app
flutter pub get
flutter run
```

### Notes on base URL

In `guido_app/lib/config/api_config.dart`:

- Android emulator uses `http://10.0.2.2:8000/api/`
- Flutter web uses `http://localhost:8000/api/`

## Folder structure (high level)

```text
GG/
├── backend/
│   ├── accounts/
│   ├── guido_backend/
│   ├── manage.py
│   └── requirements.txt
├── guido_app/
│   ├── lib/
│   └── pubspec.yaml
└── README.md
```

