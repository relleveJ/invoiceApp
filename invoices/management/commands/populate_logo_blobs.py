from django.core.management.base import BaseCommand
from invoices.models import BusinessProfile, Invoice
from django.core.files.storage import default_storage
import mimetypes

class Command(BaseCommand):
    help = 'Populate logo_blob/logo_mime for BusinessProfile and Invoice from existing ImageField files'

    def handle(self, *args, **options):
        bp_count = 0
        inv_count = 0
        # BusinessProfile
        # sanity pass (no-op) to ensure queryset evaluation happens outside the copy loop
        for bp in BusinessProfile.objects.all():
            pass
        # Iterate and copy
        for bp in BusinessProfile.objects.all():
            try:
                if bp.logo and (not bp.logo_blob):
                    name = getattr(bp.logo, 'name', None)
                    if name and default_storage.exists(name):
                        with default_storage.open(name, 'rb') as fh:
                            data = fh.read()
                        mime = mimetypes.guess_type(name)[0] or ''
                        bp.logo_blob = data
                        bp.logo_mime = mime
                        bp.save(update_fields=['logo_blob', 'logo_mime'])
                        bp_count += 1
            except Exception:
                self.stdout.write(self.style.WARNING(f'Failed to copy logo for BusinessProfile id={bp.pk}'))

        # Invoices
        for inv in Invoice.objects.all():
            try:
                if inv.business_logo and (not inv.business_logo_blob):
                    name = getattr(inv.business_logo, 'name', None)
                    if name and default_storage.exists(name):
                        with default_storage.open(name, 'rb') as fh:
                            data = fh.read()
                        mime = mimetypes.guess_type(name)[0] or ''
                        inv.business_logo_blob = data
                        inv.business_logo_mime = mime
                        inv.save(update_fields=['business_logo_blob', 'business_logo_mime'])
                        inv_count += 1
            except Exception:
                self.stdout.write(self.style.WARNING(f'Failed to copy logo for Invoice id={inv.pk}'))

        self.stdout.write(self.style.SUCCESS(f'Copied logos: BusinessProfiles={bp_count}, Invoices={inv_count}'))
