# 🚀 GUIDE DE MIGRATION LARC - Old Prod → Nouvelle Prod

Ce dossier contient tous les scripts et configurations nécessaires pour la migration de la base de données LARC.

## 📁 Structure

```
larc-migration/
├── config/
│   ├── .env.example          # Template de configuration (à copier en .env)
│   └── .env                  # Votre configuration (à créer)
├── scripts/
│   ├── 01_export_old_prod.sh      # Export Old Prod
│   ├── 02_import_non_prod.sh      # Import Non-Prod
│   ├── 03_add_sync_columns.sql    # Ajout colonnes sync_version
│   ├── 04_test_sync.sh            # Test du daemon
│   ├── sync_daemon.py             # Daemon de synchronisation
│   ├── requirements.txt           # Dépendances Python
│   ├── 05_backup_j1.sh            # Backup J-1
│   ├── 06_bascule_jour_j.sh       # Bascule Jour J
│   └── 07_rollback.sh             # Rollback si problème
├── logs/                      # Logs du daemon
└── backups/                   # Backups de la base
```

---

## ✅ PHASE 1 : PRÉPARATION

### Étape 1.1 : Créer le projet Supabase "LarcCloud"
- Allez sur https://supabase.com
- Créez un nouveau projet nommé **LarcCloud**
- Email : Larcspaceone@gmail.com
- Notez bien :
  - URL du projet
  - Clé anon (publique)
  - Clé service_role (secrète)

### Étape 1.2 : Configurer l'environnement
```bash
cd larc-migration/config
cp .env.example .env
nano .env  # Remplissez avec vos URLs et clés
```

### Étape 1.3 : Export Old Prod
```bash
cd scripts
chmod +x 01_export_old_prod.sh
./01_export_old_prod.sh
```

### Étape 1.4 : Import Non-Prod
```bash
chmod +x 02_import_non_prod.sh
./02_import_non_prod.sh
```

### Étape 1.5 : Ajouter les colonnes sync_version
```bash
# Connectez-vous à votre base Non-Prod via Supabase SQL Editor
# Copiez-collez le contenu de 03_add_sync_columns.sql
# Adaptez les noms de tables selon votre schéma
```

### Étape 1.6 : Tester le trigger
```sql
-- Dans Supabase SQL Editor (Non-Prod)
UPDATE utilisateurs SET nom = 'test' WHERE id = 1;
SELECT sync_version FROM utilisateurs WHERE id = 1;
-- Doit afficher une valeur incrémentée
```

---

## ✅ PHASE 2 : SYNC

### Étape 2.1 : Installer les dépendances
```bash
cd scripts
pip install -r requirements.txt
```

### Étape 2.2 : Tester le daemon
```bash
chmod +x 04_test_sync.sh
./04_test_sync.sh
```

### Étape 2.3 : Lancer le daemon en continu (test 24h)
```bash
nohup python3 sync_daemon.py > ../logs/sync_daemon.log 2>&1 &
```

### Étape 2.4 : Vérifier les logs
```bash
tail -f ../logs/sync_daemon.log
```

---

## ✅ PHASE 3 : TESTS APPS

### Web (Reflex)
1. Modifier `.env` ou la config pour pointer vers `NON_PROD_URL`
2. Redémarrer l'application
3. Tester les opérations CRUD

### Desktop (Delphi/Lazarus)
1. Mettre à jour la chaîne de connexion
2. Recompiler si nécessaire
3. Tester

### Mobile (FlutterFlow)
1. Mettre à jour les variables d'environnement
2. Redéployer
3. Tester

### Test de synchronisation
1. Modifier une donnée sur une app
2. Vérifier que les 2 autres apps reçoivent la modification
3. Vérifier dans les logs du daemon

---

## ✅ PHASE 4 : BASCULE PROD

### J-1 (Veille)
```bash
cd scripts
chmod +x 05_backup_j1.sh
./05_backup_j1.sh
```

✅ Checklist J-1 :
- [ ] Backup Old Prod complet
- [ ] Fichier .env.backup créé
- [ ] Utilisateurs prévenus

### Jour J (15 minutes)
```bash
chmod +x 06_bascule_jour_j.sh
./06_bascule_jour_j.sh
```

**Déroulé :**
- **T+00** : Apps en maintenance + stop daemon
- **T+05** : Dernière synchro Old→NonProd
- **T+10** : Changement URLs des 3 apps → Non-Prod
- **T+15** : Daemon NonProd↔Cloud + fin maintenance

---

## 🛡️ ROLLBACK (si problème)

```bash
chmod +x 07_rollback.sh
./07_rollback.sh
```

Ce script :
1. Arrête le daemon actuel
2. Restaure le fichier .env de backup
3. Redémarre le daemon pointant vers Old Prod
4. Vous guide pour redémarrer les apps

---

## ✅ CHECKLIST FINALE

- [ ] Export Old Prod OK
- [ ] Non-Prod créé + triggers OK
- [ ] Daemon testé 24h sans erreur
- [ ] 3 apps testées (Web, Desktop, Mobile)
- [ ] Backup J-1 fait
- [ ] Bascule exécutée
- [ ] 7 jours stables → archiver Old Prod

---

## 📞 SUPPORT

En cas de problème :
1. Consultez les logs : `../logs/sync_daemon.log`
2. Vérifiez la connectivité Supabase
3. Exécutez le rollback si nécessaire

---

> [!SUCCESS] Migration terminée 🎉
