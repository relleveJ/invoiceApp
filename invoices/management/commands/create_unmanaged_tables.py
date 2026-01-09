from django.core.management.base import BaseCommand
from django.db import connection, transaction

class Command(BaseCommand):
    help = 'Create minimal unmanaged tables (invoice_templates, users_activity_logs) if they do not exist.'

    def handle(self, *args, **options):
        with connection.cursor() as cur:
            # Create invoice_templates table if missing
            cur.execute("""
            CREATE TABLE IF NOT EXISTS invoice_templates (
                template_id BIGSERIAL PRIMARY KEY,
                template_name TEXT NOT NULL,
                template_layout TEXT NOT NULL,
                is_default BOOLEAN NOT NULL DEFAULT FALSE,
                created_date TIMESTAMP WITH TIME ZONE NULL
            );
            """)
            self.stdout.write(self.style.SUCCESS('Ensured table: invoice_templates'))

            # Create users_activity_logs table if missing
            cur.execute("""
            CREATE TABLE IF NOT EXISTS users_activity_logs (
                activity_id BIGSERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL,
                activity_type VARCHAR(200) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                related_invoice VARCHAR(200)
            );
            """)
            self.stdout.write(self.style.SUCCESS('Ensured table: users_activity_logs'))

        # Commit if needed (cursor context handles this for most DBs)
        self.stdout.write(self.style.SUCCESS('create_unmanaged_tables completed.'))
