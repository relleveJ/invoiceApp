release: ./entrypoint.sh python manage.py migrate --noinput && python manage.py collectstatic --noinput
# Use the entrypoint wrapper to run migrations/collectstatic then exec Gunicorn.
# This ensures Railway (non-Docker) deployments run the setup steps before start.
web: ./entrypoint.sh gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --threads 4
