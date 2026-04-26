#!/bin/bash
# Script d'export de la base Old Prod
# Nécessite Docker avec postgres:16

# Configuration
OLD_PROD_URL="your-old-prod.supabase.co"
DB_PASSWORD="your-db-password"
OUTPUT_FILE="../backups/old_prod_export_$(date +%Y%m%d_%H%M%S).sql"

echo "🚀 Export Old Prod vers $OUTPUT_FILE"

# Export complet avec pg_dump via Docker
docker run --rm \
  -e PGPASSWORD="$DB_PASSWORD" \
  postgres:16 \
  pg_dump -h "$OLD_PROD_URL" \
  -U postgres \
  -d postgres \
  --verbose \
  --format=custom \
  --file=/tmp/export.dump > "$OUTPUT_FILE"

echo "✅ Export terminé : $OUTPUT_FILE"
