# Invoice Maker - Online Invoice Maker

## Description
A simple online invoice maker for small businesses and freelancers. Create professional invoices, manage clients, export PDFs, and track activity with a lightweight admin UI.

## Ad Integration Strategy
Ads are placed contextually (auth pages, sidebar, dashboard widgets, confirmation screens) to surface helpful third-party services (templates, payments, bookkeeping). CTAs are short and contextual to increase relevance; clicks are tracked with a non-blocking beacon to minimize UX friction.

## Live Demo
**Try It Now:** https://invoiceapp-production-d555.up.railway.app/
**Demo Credentials:** 
username: `admin1234`  
password: `adminadmin1234`

## Tech Stack
- Django 5.0
- PostgreSQL
- Bootstrap 5 (CSS)
- Vanilla JavaScript (ad tracking helpers)
- WeasyPrint (PDF generation)

## Local Setup Instructions
1. Clone repository

```bash
git clone <your-repo-url>
cd invoiceApp
```

2. Create and activate a Python virtualenv, then install dependencies

```bash
python -m venv .venv
.venv\Scripts\activate    # Windows
pip install -r requirements.txt
```

3. Configure environment variables (copy `.env` and edit) — set `DATABASE_URL`, `SECRET_KEY`, `DEBUG`, etc.

4. Setup PostgreSQL and update `DATABASE_URL` accordingly.

5. Run migrations and collectstatic

```bash
python manage.py migrate
python manage.py collectstatic --noinput
```

6. Create a superuser

```bash
python manage.py createsuperuser
```

7. Start the dev server

```bash
python manage.py runserver
```

## Deployment
For production deployment instructions (Railway one-click deploy and Docker), see [README_RAILWAY_DEPLOY.md](README_RAILWAY_DEPLOY.md).


## Database Schema

Below is the table schema used by the application. Use this as a reference for migrations, exports, or documentation.

- Users
	- User ID
	- Business name
	- Business logo (file path / URL)
	- Business address
	- Business contact (phone/email)
	- Created date (timestamp)
	- Last login (timestamp)

- Clients
	- Client ID
	- User ID (owner)
	- Client business (name)
	- Client email
	- Client phone
	- Client address
	- Created date (timestamp)

- Invoices
	- Invoice ID
	- User ID (owner)
	- Client ID
	- Invoice number
	- Invoice date
	- Due date
	- Status (draft, sent, paid, overdue)
	- Subtotal
	- Tax rate (%)
	- Tax amount
	- Discount amount
	- Total amount
	- Currency
	- Payment terms
	- Notes
	- Created timestamp
	- Last modified timestamp
	- PDF generated (boolean / filepath)

- Invoice Items
	- Item ID
	- Invoice ID
	- Item description
	- Quantity
	- Unit price / rate
	- Line total
	- Order / position

- Ad Clicks
	- Click ID
	- User / Session ID
	- Ad identifier
	- Ad placement location
	- Timestamp
	- Target URL
	- User context
	- Invoice ID (optional)

- Users_Activity_Log
	- Activity ID
	- User ID
	- Activity type (invoice_created, ad_clicked, etc...)
	- Timestamp
	- Related invoice ID


## Features
- Create, edit, and soft-delete invoices
- Line-item management with totals and tax calculations
- Client management (create/edit/list)
- PDF export / download via WeasyPrint
- Invoice templates support
- Activity logs and superadmin tools
- Admin UI to manage users and superadmins
- Contextual ad placements with dismiss and click tracking

## Ad Click Analytics
Ad clicks are tracked client-side with `navigator.sendBeacon` (or fetch fallback) to `/track-ad-click/` and persisted to the `AdClick` model. The tracking is lightweight and non-blocking to avoid impacting navigation.

## Screenshots
Add 5–7 screenshots
- Invoice creation form
- PDF output
- Client management
- Invoice history
- Ad placements
- Dashboard (if applicable)

(Place image files and reference them here when ready.)

## PDF Generation
PDFs are generated using WeasyPrint (configured in `requirements.txt`). The HTML invoice templates are rendered server-side and passed to WeasyPrint to produce A4 PDFs.

## Future Enhancements
- More invoice templates
- Visual polish
- Payment gateway integrations (Stripe, PayPal)
- Email function
- Reporting & export features


