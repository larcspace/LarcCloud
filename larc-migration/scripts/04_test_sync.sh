#!/bin/bash
# Script de test du sync daemon
# Exécute une seule boucle de synchronisation pour vérification

cd "$(dirname "$0")"

echo "🧪 Test du Sync Daemon (une boucle)"

# Installer les dépendances si nécessaire
pip install -r requirements.txt --quiet

# Exécuter une seule fois
python3 -c "
from sync_daemon import SyncDaemon
from dotenv import load_dotenv
load_dotenv('../config/.env')

daemon = SyncDaemon()
daemon.run_once()
"

echo "✅ Test terminé. Vérifiez ../logs/sync_daemon.log pour les détails."
