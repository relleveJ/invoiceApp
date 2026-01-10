FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies required for Pillow, psycopg2, and optional wkhtmltopdf
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libpq-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libssl-dev \
    pkg-config \
    curl \
    ca-certificates \
    fonts-liberation \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*
# Note: `wkhtmltopdf` is not available in the Debian package repo used by this
# base image (causes build failures on Railway). This project uses ReportLab
# for PDF generation by default; if you need `wkhtmltopdf`, install a
# prebuilt binary or add the appropriate APT repository in a custom image.
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (leverages Docker layer cache)
COPY requirements.txt /app/
RUN python -m pip install --upgrade pip setuptools wheel
RUN python -m pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Create a volume location for collectstatic output
RUN mkdir -p /vol/static

# Add entrypoint that runs migrations and collectstatic before starting
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
# Make wkhtmltopdf command path available to the Django settings fallback
ENV WKHTMLTOPDF_CMD=/usr/bin/wkhtmltopdf
# Use a shell CMD so the $PORT env var (set by Railway) is expanded. If PORT
# is not set, default to 8000.
CMD sh -c "gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000}"
