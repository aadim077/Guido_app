from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Seed test users (admin + regular user)"

    def handle(self, *args, **options):
        User = get_user_model()

        admin_email = "admin@guido.com"
        admin_username = "admin"
        admin_password = "admin123"

        user_email = "user@guido.com"
        user_username = "testuser"
        user_password = "user123"

        admin, created = User.objects.get_or_create(
            email=admin_email,
            defaults={"username": admin_username},
        )
        if created:
            admin.set_password(admin_password)

        # keep this consistent even if the record existed already
        admin.username = admin_username
        admin.role = "admin"
        admin.is_staff = True
        admin.is_superuser = True
        admin.save()
        self.stdout.write(self.style.SUCCESS(f"Admin ready: {admin_email}"))

        user, created = User.objects.get_or_create(
            email=user_email,
            defaults={"username": user_username},
        )
        if created:
            user.set_password(user_password)

        user.username = user_username
        user.role = "user"
        user.is_staff = False
        user.is_superuser = False
        user.save()
        self.stdout.write(self.style.SUCCESS(f"User ready: {user_email}"))

