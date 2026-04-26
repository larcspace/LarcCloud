#!/bin/bash
# Script de bascule - Jour J (15 minutes)
# À exécuter le jour de la migration

set -e

echo "🚀 BASCULE PROD - JOUR J"
echo "========================"
echo ""

# Charger les variables d'environnement
if [ -f "../config/.env" ]; then
    export $(grep -v '^#' ../config/.env | xargs)
fi

# Fonction pour afficher l'heure et le message
log_step() {
    echo "[$(date '+%H:%M')] $1"
}

# T+00 : Apps en maintenance + stop daemon
log_step "T+00 : Mise en maintenance des applications..."
echo "  ⚠️  Arrêt du sync daemon..."
pkill -f sync_daemon.py 2>/dev/null || echo "  → Aucun daemon en cours d'exécution"
echo "  → Applications en mode maintenance (à faire manuellement sur chaque app)"
sleep 2

# T+05 : Dernière synchro Old→NonProd
log_step "T+05 : Dernière synchronisation Old Prod → Non-Prod..."
echo "  → Lancement de la dernière synchro..."
cd "$(dirname "$0")"
python3 -c "
from sync_daemon import SyncDaemon
from dotenv import load_dotenv
load_dotenv('../config/.env')

daemon = SyncDaemon()
daemon.run_once()
" || echo "  ⚠️  Attention: erreur pendant la synchro"
sleep 2

# T+10 : Changer URLs des 3 apps → Non-Prod
log_step "T+10 : Mise à jour des configurations..."
echo ""
echo "  📝 MODIFICATIONS À EFFECTUER MANUELLEMENT :"
echo ""
echo "  1. WEB (Reflex) :"
echo "     - Modifier .env ou config pour pointer vers NON_PROD_URL"
echo "     - URL actuelle: $OLD_PROD_URL"
echo "     - Nouvelle URL: $NON_PROD_URL"
echo ""
echo "  2. DESKTOP (Delphi/Lazarus) :"
echo "     - Mettre à jour la chaîne de connexion dans le code/config"
echo "     - Recompiler si nécessaire"
echo ""
echo "  3. MOBILE (FlutterFlow) :"
echo "     - Mettre à jour les variables d'environnement dans FlutterFlow"
echo "     - Redéployer l'application"
echo ""
read -p "  ✅ Avez-vous terminé les modifications ? (oui/non) " confirm
if [ "$confirm" != "oui" ]; then
    echo "❌ Bascule annulée. Vérifiez les modifications."
    exit 1
fi

# T+15 : Daemon → NonProd↔Cloud + lever maintenance
log_step "T+15 : Redémarrage du daemon et fin de maintenance..."
echo "  → Démarrage du daemon en background..."
nohup python3 sync_daemon.py > ../logs/daemon_output.log 2>&1 &
DAEMON_PID=$!
echo "  → Daemon démarré (PID: $DAEMON_PID)"
echo ""
echo "  ✅ MAINTENANCE TERMINÉE"
echo "  → Les applications peuvent être réactivées"
echo ""

# Vérification rapide
sleep 5
echo "🧪 Vérification rapide..."
if ps -p $DAEMON_PID > /dev/null; then
    echo "  ✅ Daemon en cours d'exécution"
else
    echo "  ❌ Daemon arrêté unexpectedly"
fi

echo ""
echo "✅ BASCULE TERMINÉE"
echo "📊 Surveillez les logs dans ../logs/"
