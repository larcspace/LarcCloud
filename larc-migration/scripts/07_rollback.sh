#!/bin/bash
# Script de ROLLBACK en cas de problème
# À exécuter si la bascule échoue

set -e

echo "🛑 ROLLBACK - Retour à Old Prod"
echo "=============================="
echo ""

# Vérifier que le backup existe
BACKUP_FILE=$(ls -t ../config/.env.backup.* 2>/dev/null | head -1)

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Aucun fichier de backup .env trouvé !"
    echo "   Cherchez manuellement dans ../config/"
    exit 1
fi

echo "📁 Backup trouvé : $BACKUP_FILE"
read -p "Confirmez-vous le rollback ? (oui/non) " confirm

if [ "$confirm" != "oui" ]; then
    echo "❌ Rollback annulé"
    exit 0
fi

# Arrêter le daemon actuel
echo ""
echo "⏹️  Arrêt du daemon actuel..."
pkill -f sync_daemon.py 2>/dev/null || echo "→ Aucun daemon en cours"

# Restaurer le backup
echo ""
echo "📋 Restauration du fichier .env..."
cp "$BACKUP_FILE" ../config/.env
echo "✅ .env restauré depuis $BACKUP_FILE"

# Redémarrer les apps (instructions)
echo ""
echo "🔄 ACTIONS REQUISES :"
echo ""
echo "1. WEB (Reflex) :"
echo "   - Redémarrer l'application web"
echo "   - Vérifier qu'elle pointe vers Old Prod"
echo ""
echo "2. DESKTOP (Delphi/Lazarus) :"
echo "   - Redémarrer l'application desktop"
echo "   - Vérifier la connexion"
echo ""
echo "3. MOBILE (FlutterFlow) :"
echo "   - Redéployer avec l'ancienne configuration"
echo ""
echo "4. Daemon :"
echo "   - Le daemon pointera maintenant vers Old Prod ↔ Cloud"
echo ""

read -p "Avez-vous terminé les modifications ? (oui/non) " confirm2
if [ "$confirm2" != "oui" ]; then
    echo "⚠️  Attention: certaines applications peuvent ne pas être synchronisées"
fi

# Redémarrer le daemon
echo ""
echo "🚀 Redémarrage du daemon..."
cd "$(dirname "$0")"
nohup python3 sync_daemon.py > ../logs/daemon_output.log 2>&1 &
DAEMON_PID=$!
echo "→ Daemon démarré (PID: $DAEMON_PID)"

sleep 3
if ps -p $DAEMON_PID > /dev/null; then
    echo "✅ Daemon en cours d'exécution"
else
    echo "❌ Problème: daemon non démarré"
    exit 1
fi

echo ""
echo "✅ ROLLBACK TERMINÉ"
echo "📊 Vérifiez que toutes les apps fonctionnent correctement"
