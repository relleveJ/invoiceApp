import os
import sys
import secrets

# Configure Django settings
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()
# Default credentials (can be overridden via env vars)
# NOTE: these defaults are intentionally set per user request; change in production.
username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
# Use provided env var or default to requested password
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'adminInvoicemaker159')

existing = User.objects.filter(username=username).first()
if existing:
    print(f"Superuser '{username}' already exists.")
    # If an explicit password env var was provided, update the existing user's password
    if os.environ.get('DJANGO_SUPERUSER_PASSWORD'):
        existing.set_password(password)
        existing.save()
        print('Superuser password updated from DJANGO_SUPERUSER_PASSWORD env var.')
else:
    User.objects.create_superuser(username=username, email=email, password=password)
    print('Superuser created:')
    print(f'  username: {username}')
    print(f'  email: {email}')
    print(f'  password: {password}')
    if password == 'adminInvoicemaker159' and not os.environ.get('DJANGO_SUPERUSER_PASSWORD'):
        print('WARNING: Using default superuser password. It is recommended to set DJANGO_SUPERUSER_PASSWORD env var in production.')
