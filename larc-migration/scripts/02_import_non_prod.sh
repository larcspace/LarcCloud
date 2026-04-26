#!/bin/bash
# Script d'import vers Non-Prod
# Nécessite Docker avec postgres:16

# Configuration
NON_PROD_URL="your-non-prod.supabase.co"
DB_PASSWORD="your-db-password"
INPUT_FILE="../backups/old_prod_export_YYYYMMDD_HHMMSS.sql"

echo "🚀 Import vers Non-Prod depuis $INPUT_FILE"

# Vérifier que le fichier existe
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Fichier d'export introuvable : $INPUT_FILE"
  exit 1
fi

# Import avec pg_restore via Docker
docker run --rm \
  -e PGPASSWORD="$DB_PASSWORD" \
  -v "$(pwd)/$INPUT_FILE:/tmp/import.dump" \
  postgres:16 \
  pg_restore -h "$NON_PROD_URL" \
  -U postgres \
  -d postgres \
  --verbose \
  --clean \
  --if-exists \
  /tmp/import.dump

echo "✅ Import terminé"
