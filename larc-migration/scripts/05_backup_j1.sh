#!/bin/bash
# Script de backup complet Old Prod (J-1)
# À exécuter la veille de la bascule

BACKUP_DIR="../backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$BACKUP_DIR/backup_final_old_prod_$TIMESTAMP.sql"

echo "🛡️  BACKUP COMPLET OLD PROD (J-1)"
echo "================================"
echo "Destination: $OUTPUT_FILE"

# Charger les variables d'environnement
if [ -f "../config/.env" ]; then
    export $(grep -v '^#' ../config/.env | xargs)
fi

DB_PASSWORD="$OLD_PROD_SERVICE_ROLE_KEY"
OLD_PROD_URL="$OLD_PROD_URL"

# Export complet
docker run --rm \
  -e PGPASSWORD="$DB_PASSWORD" \
  postgres:16 \
  pg_dump -h "$OLD_PROD_URL" \
  -U postgres \
  -d postgres \
  --verbose \
  --format=custom \
  --file=/tmp/backup_final.dump > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup réussi : $OUTPUT_FILE"
    echo "📦 Taille: $(du -h "$OUTPUT_FILE" | cut -f1)"
else
    echo "❌ Échec du backup"
    exit 1
fi

# Copie de sécurité des .env actuels
echo ""
echo "📋 Sauvegarde des fichiers .env..."
cp ../config/.env ../config/.env.backup.$TIMESTAMP 2>/dev/null || echo "⚠️  Aucun fichier .env trouvé"

echo ""
echo "✅ Procédure J-1 terminée"
