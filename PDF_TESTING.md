# PDF Backend Testing & Railway Deployment

This file contains quick steps to verify the PDF endpoints locally and notes for deploying the Docker image to Railway.

Local verification (recommended prerequisites)
- Docker installed (preferred), or
- Optional: install `wkhtmltopdf` on the host if you need HTML-to-PDF rendering; otherwise ReportLab (default) is sufficient.

Quick: build & run with Docker

1. Build the image (from project root):

```powershell
docker build -t invoiceapp:test .
```

2. Run the container (exposes port 8000):

```powershell
docker run -p 8000:8000 -e PORT=8000 invoiceapp:test
```

The image's entrypoint runs migrations/collectstatic; after the container is up you can open `http://localhost:8000`.

Testing endpoints

- Diagnostic: `GET /pdf-status/` (requires login). This returns JSON about ReportLab and wkhtmltopdf availability.
- Preview/pdf: `POST /invoices/preview/?format=pdf` with JSON preview payload. The server will return `application/pdf` if a PDF backend succeeded, otherwise HTML fallback.

PowerShell test helper
----------------------

Use the script `scripts/test_pdf_endpoints.ps1` included in the repo. Example:

```powershell
.\scripts\test_pdf_endpoints.ps1 -BaseUrl http://localhost:8000 -Username <user> -Password <pass>
```

The script logs in, calls `/pdf-status/`, then POSTs a small preview JSON and saves the output as `scripts/preview_output.pdf` (or `scripts/preview_fallback.html` if not PDF).

Curl equivalents

1. Fetch login page and extract CSRF (save login.html):

```bash
curl -c cookies.txt "http://localhost:8000/" -o login.html
# extract csrfmiddlewaretoken from login.html, then:
curl -b cookies.txt -c cookies.txt -d "username=USER&password=PASS&csrfmiddlewaretoken=TOKEN" -X POST http://localhost:8000/login/
curl -b cookies.txt http://localhost:8000/pdf-status/
curl -b cookies.txt -H "Accept: application/pdf" -H "Content-Type: application/json" --data '{"invoice_number":"T","invoice_date":"2026-01-01","due_date":"2026-02-01","client":{"name":"X"},"items":[{"description":"x","quantity":1,"unit_price":10}]}' "http://localhost:8000/invoices/preview/?format=pdf" --output preview.pdf
```

Railway deployment (Docker)
--------------------------

Railway supports Docker-based deployments. A recommended flow:

1. Build and push the image to Docker Hub or a registry accessible to Railway:

```bash
docker build -t <hub-user>/invoiceapp:latest .
docker push <hub-user>/invoiceapp:latest
```

2. On Railway, create a new project and choose the `Deploy from Docker Hub` option (or connect your GitHub repo and set up a Dockerfile build).

3. Set environment variables in Railway:
- `DJANGO_SECRET_KEY` (or use default dev key locally)
- `DATABASE_URL` (Postgres or Railway-provided DB)
- `PORT` = `8000`

The Dockerfile does not install `wkhtmltopdf` by default; this project uses ReportLab for PDF generation (ReportLab is included in `requirements.txt` and does not require native GLib/Pango/Cairo libraries). If you prefer `wkhtmltopdf`, install a prebuilt binary into the image or set `WKHTMLTOPDF_CMD` in the environment and ensure the binary is present in the runtime.

After deployment, use the same `scripts/test_pdf_endpoints.ps1` or curl commands against the Railway-provided URL to verify PDF generation.

If you'd like, I can:
- Add a tiny `/debug/pdf` page that shows a HTML preview and a direct `Download PDF` link for manual testing.
- Add a GitHub Actions workflow to build and push the Docker image automatically on commits.
