Railway One-Click Deploy — InvoiceApp

Overview

This repository is prepared for a one-click / simple deploy on Railway (https://railway.app).
The project supports both Docker-based (recommended) and non-Docker deployments. PDF generation and system libraries required by WeasyPrint are only guaranteed in the Docker environment provided.

Key changes made

- `Procfile` updated to run `./entrypoint.sh` before starting Gunicorn so migrations and `collectstatic` run automatically on release/start.
- `entrypoint.sh` waits for Postgres if `DATABASE_URL` points to Postgres, runs `makemigrations`/`migrate`, and runs `collectstatic`.
- `config/settings.py` updated to read `DATABASE_URL` via `dj-database-url`, enable optional S3-backed media (via `django-storages`), and use environment variables for PDF backend and wkhtmltopdf path.
- `requirements.txt` includes `django-storages[boto3]` and `boto3` for optional S3 support.
- `Dockerfile` updated so Gunicorn binds to Railway's `$PORT` when available.

Recommended deployment (Docker — recommended)

1. Push this repo to a Git provider (GitHub/GitLab).
2. In Railway, create a new project and choose "Deploy from GitHub" (or manual Git repo).
3. Use the Dockerfile deployment option (Railway will build the image).
4. Add the PostgreSQL plugin in Railway — Railway will provide a `DATABASE_URL` env var.
5. Set required Railway environment variables (see below).
6. Deploy. The `release` and `web` commands in `Procfile` are configured to run `./entrypoint.sh` which runs migrations and `collectstatic`.

Required environment variables (Railway Environment)

- `SECRET_KEY` — strong Django secret key (required).
- `DEBUG` — set to `False` in production.
- `DATABASE_URL` — Railway provides this when you add the PostgreSQL plugin.

Optional (recommended for persistent uploads)

- `USE_S3=true` — enable S3 media storage (or set `AWS_STORAGE_BUCKET_NAME`).
- `AWS_ACCESS_KEY_ID` — S3 credentials.
- `AWS_SECRET_ACCESS_KEY` — S3 credentials.
- `AWS_STORAGE_BUCKET_NAME` — S3 bucket.
- `AWS_S3_REGION_NAME` — optional.
- `AWS_S3_ENDPOINT_URL` — optional (for S3-compatible providers).
- `WKHTMLTOPDF_CMD` — optional path to wkhtmltopdf if using wkhtmltopdf instead of ReportLab.
- `PDF_BACKEND` — defaults to `reportlab`.

Notes on static files and media

- Static files are collected to `STATIC_ROOT` and served by WhiteNoise (`STATICFILES_STORAGE` configured).
- User-uploaded media uses `MEDIA_ROOT` by default (filesystem). Railway's filesystem may be ephemeral — to persist uploads across redeploys, enable S3 (recommended) by setting `USE_S3=true` and the AWS_* variables above.
- Alternatively, configure a Railway persistent volume and set `MEDIA_ROOT` to that path via an environment variable or Railway volume mount.

PDF generation

- ReportLab is included in `requirements.txt`. If you prefer an HTML-to-PDF renderer (wkhtmltopdf), set `WKHTMLTOPDF_CMD` and ensure the binary is available in the environment.
- If you deploy without Docker, you must ensure those system packages are available in the runtime environment.

One-click (button) configuration

- If you want a GitHub one-click deploy button, create a Railway template and point it to this repository. Ensure the Railway template uses the Docker deployment option for a consistent runtime environment.

Post-deploy checklist (what to verify)

- Application boots and responds on `/` and `/dashboard/`.
- Create a user and create an invoice.
- Generate/download PDF from an invoice to confirm ReportLab works.
- Verify data persists after redeploy (Postgres should persist automatically).
- If you are relying on filesystem media, verify uploads remain after a redeploy or configure S3/persistent volume.

If you want, I can:
- Add a small Railway `railway.json` template (or `railway` template files) for one-click deploy.
- Add S3 example configuration in a settings example file.
- Run a local smoke test script to validate migrations and PDF rendering inside Docker.


