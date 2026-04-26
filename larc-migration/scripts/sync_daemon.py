#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LARC Sync Daemon - Synchronisation bidirectionnelle
Entre Non-Prod et Cloud (Supabase)

Phase 2 : SYNC
"""

import os
import time
import logging
from datetime import datetime
from typing import Dict, List, Optional
from supabase import create_client, Client

# Configuration
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL_SECONDS", "60"))
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "100"))

# Tables à synchroniser (à adapter selon votre schéma)
TABLES_TO_SYNC = [
    "utilisateurs",
    "projets",
    "documents",
    # Ajoutez vos tables ici
]

# Setup logging
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('../logs/sync_daemon.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class SyncDaemon:
    def __init__(self):
        """Initialise les clients Supabase pour Non-Prod et Cloud"""
        
        # Non-Prod Configuration
        non_prod_url = os.getenv("NON_PROD_URL")
        non_prod_key = os.getenv("NON_PROD_SERVICE_ROLE_KEY")
        
        # Cloud Configuration
        cloud_url = os.getenv("CLOUD_URL")
        cloud_key = os.getenv("CLOUD_SERVICE_ROLE_KEY")
        
        if not all([non_prod_url, non_prod_key, cloud_url, cloud_key]):
            raise ValueError("Configuration incomplete. Vérifiez vos variables d'environnement.")
        
        self.non_prod: Client = create_client(non_prod_url, non_prod_key)
        self.cloud: Client = create_client(cloud_url, cloud_key)
        
        logger.info("✅ SyncDaemon initialisé")
        logger.info(f"   Non-Prod: {non_prod_url}")
        logger.info(f"   Cloud: {cloud_url}")

    def get_latest_sync_version(self, table: str, source: Client) -> int:
        """Récupère la dernière version de sync pour une table"""
        try:
            response = source.table(table).select("sync_version").order("sync_version", desc=True).limit(1).execute()
            if response.data and len(response.data) > 0:
                return response.data[0]["sync_version"]
            return 0
        except Exception as e:
            logger.error(f"Erreur get_latest_sync_version ({table}): {e}")
            return 0

    def get_modified_records(self, table: str, source: Client, since_version: int) -> List[Dict]:
        """Récupère les enregistrements modifiés depuis une version donnée"""
        try:
            response = source.table(table).select("*").gt("sync_version", since_version).execute()
            return response.data if response.data else []
        except Exception as e:
            logger.error(f"Erreur get_modified_records ({table}): {e}")
            return []

    def upsert_record(self, table: str, target: Client, record: Dict):
        """Insère ou met à jour un enregistrement"""
        try:
            # On retire l'ID si c'est un insert, ou on le garde pour update
            record_id = record.get("id")
            data = {k: v for k, v in record.items() if k != "sync_version"}
            
            response = target.table(table).upsert(data, on_conflict="id").execute()
            logger.debug(f"Upsert réussi dans {table} pour id={record_id}")
            return True
        except Exception as e:
            logger.error(f"Erreur upsert ({table}, id={record.get('id')}): {e}")
            return False

    def sync_table(self, table: str):
        """Synchronise une table entre Non-Prod et Cloud (bidirectionnel)"""
        logger.info(f"🔄 Synchronisation de la table: {table}")
        
        try:
            # Récupérer les dernières versions de chaque côté
            non_prod_version = self.get_latest_sync_version(table, self.non_prod)
            cloud_version = self.get_latest_sync_version(table, self.cloud)
            
            logger.debug(f"   Non-Prod version: {non_prod_version}, Cloud version: {cloud_version}")
            
            # Si Non-Prod est plus récent → pousser vers Cloud
            if non_prod_version > cloud_version:
                records = self.get_modified_records(table, self.non_prod, cloud_version)
                logger.info(f"   → {len(records)} enregistrement(s) à pousser vers Cloud")
                
                for record in records:
                    self.upsert_record(table, self.cloud, record)
            
            # Si Cloud est plus récent → tirer vers Non-Prod
            if cloud_version > non_prod_version:
                records = self.get_modified_records(table, self.cloud, non_prod_version)
                logger.info(f"   → {len(records)} enregistrement(s) à tirer vers Non-Prod")
                
                for record in records:
                    self.upsert_record(table, self.non_prod, record)
            
            # Si versions égales → pas de changement
            if non_prod_version == cloud_version:
                logger.debug(f"   ✓ Déjà synchronisé (version {non_prod_version})")
                
        except Exception as e:
            logger.error(f"❌ Erreur sync_table ({table}): {e}")

    def run_once(self):
        """Exécute une boucle de synchronisation complète"""
        logger.info("=" * 50)
        logger.info(f"Début synchronisation à {datetime.now().isoformat()}")
        
        for table in TABLES_TO_SYNC:
            self.sync_table(table)
        
        logger.info(f"Fin synchronisation à {datetime.now().isoformat()}")
        logger.info("=" * 50)

    def run_daemon(self):
        """Lance le daemon en continu"""
        logger.info("🚀 Lancement du SyncDaemon...")
        logger.info(f"   Intervalle: {SYNC_INTERVAL}s")
        logger.info(f"   Tables: {', '.join(TABLES_TO_SYNC)}")
        
        try:
            while True:
                self.run_once()
                time.sleep(SYNC_INTERVAL)
        except KeyboardInterrupt:
            logger.info("⏹️  Arrêt du daemon demandé par l'utilisateur")
        except Exception as e:
            logger.error(f"❌ Erreur critique: {e}")
            raise


if __name__ == "__main__":
    # Charger les variables d'environnement depuis .env
    from dotenv import load_dotenv
    load_dotenv("../config/.env")
    
    daemon = SyncDaemon()
    daemon.run_daemon()
