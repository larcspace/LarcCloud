# 📋 CHECKLIST DE MIGRATION LARC

Imprimez cette checklist et cochez les cases au fur et à mesure.

---

## ✅ PHASE 1 : PRÉPARATION

### Infrastructure
- [ ] Créer projet Supabase "LarcCloud" sur https://supabase.com
- [ ] Email : Larcspaceone@gmail.com
- [ ] Noter l'URL du projet : _______________________________
- [ ] Noter la clé anon : _______________________________
- [ ] Noter la clé service_role : _______________________________

### Configuration locale
- [ ] Copier `.env.example` vers `.env` dans `config/`
- [ ] Remplir toutes les URLs et clés dans `.env`
- [ ] Vérifier que Docker est installé (`docker --version`)

### Export/Import
- [ ] Exécuter `01_export_old_prod.sh`
- [ ] Vérifier que le backup est créé dans `backups/`
- [ ] Exécuter `02_import_non_prod.sh`
- [ ] Vérifier que l'import s'est bien passé

### Base de données
- [ ] Exécuter `03_add_sync_columns.sql` dans Supabase SQL Editor (Non-Prod)
- [ ] Adapter les noms de tables selon votre schéma
- [ ] Tester un UPDATE sur une table
- [ ] Vérifier que `sync_version` s'incrémente

---

## ✅ PHASE 2 : SYNC

### Installation
- [ ] Installer Python 3.8+
- [ ] Exécuter `pip install -r requirements.txt`
- [ ] Vérifier que `supabase` est installé

### Tests
- [ ] Exécuter `04_test_sync.sh`
- [ ] Vérifier les logs dans `logs/sync_daemon.log`
- [ ] Corriger les erreurs éventuelles

### Test 24h
- [ ] Lancer le daemon : `nohup python3 sync_daemon.py > ../logs/sync_daemon.log 2>&1 &`
- [ ] Noter le PID du daemon : _______
- [ ] Attendre 24h
- [ ] Vérifier qu'il n'y a aucune erreur dans les logs
- [ ] Compter le nombre de synchronisations : _______

---

## ✅ PHASE 3 : TESTS APPS

### Web (Reflex)
- [ ] Modifier la config pour pointer vers NON_PROD_URL
- [ ] Redémarrer l'application
- [ ] Tester création/modification/suppression
- [ ] Vérifier que les données sont synchronisées

### Desktop (Delphi/Lazarus)
- [ ] Mettre à jour la chaîne de connexion
- [ ] Recompiler si nécessaire
- [ ] Tester les opérations CRUD
- [ ] Vérifier la synchronisation

### Mobile (FlutterFlow)
- [ ] Mettre à jour les variables d'environnement
- [ ] Redéployer l'application
- [ ] Tester sur appareil réel
- [ ] Vérifier la synchronisation

### Test inter-apps
- [ ] Modifier une donnée sur Web
- [ ] Vérifier que Desktop voit la modification
- [ ] Vérifier que Mobile voit la modification
- [ ] Faire l'inverse (Mobile → Web/Desktop)

---

## ✅ PHASE 4 : BASCULE PROD

### J-1 (Veille)
- [ ] Prévenir tous les utilisateurs (email/notification)
- [ ] Exécuter `05_backup_j1.sh`
- [ ] Vérifier que le backup complet est créé
- [ ] Vérifier que `.env.backup` est créé
- [ ] Noter l'emplacement du backup : _______________________________

### Jour J (15 minutes max)

**T+00 (Début)**
- [ ] Mettre les applications en mode maintenance
- [ ] Arrêter le daemon de test
- [ ] Noter l'heure de début : _______

**T+05**
- [ ] Exécuter la dernière synchro Old→NonProd
- [ ] Vérifier qu'aucune erreur ne se produit

**T+10**
- [ ] Changer URL Web (Reflex) → NON_PROD_URL
- [ ] Changer URL Desktop → NON_PROD_URL
- [ ] Changer URL Mobile → NON_PROD_URL
- [ ] Vérifier que chaque app pointe vers Non-Prod

**T+15 (Fin)**
- [ ] Configurer le daemon pour NonProd↔Cloud
- [ ] Démarrer le daemon en production
- [ ] Lever le mode maintenance
- [ ] Tester chaque application
- [ ] Noter l'heure de fin : _______

### J+1 à J+7
- [ ] Surveiller les logs quotidiennement
- [ ] Vérifier qu'aucune erreur ne se produit
- [ ] Confirmer que les utilisateurs n'ont pas de problème
- [ ] Après 7 jours : archiver Old Prod

---

## 🛡️ ROLLBACK (si nécessaire)

- [ ] Identifier le problème
- [ ] Décider du rollback avec l'équipe
- [ ] Exécuter `07_rollback.sh`
- [ ] Suivre les instructions du script
- [ ] Vérifier que toutes les apps fonctionnent
- [ ] Documenter l'incident

---

## ✅ CHECKLIST FINALE

- [ ] Export Old Prod OK
- [ ] Non-Prod créé + triggers OK
- [ ] Daemon testé 24h sans erreur
- [ ] 3 apps testées et validées
- [ ] Backup J-1 fait et vérifié
- [ ] Bascule exécutée avec succès
- [ ] 7 jours stables
- [ ] Old Prod archivé

---

## 📝 NOTES

Date de début de migration : _______________

Date de bascule : _______________

Personnes impliquées : 
- _______________________________
- _______________________________
- _______________________________

Problèmes rencontrés :
_______________________________________________
_______________________________________________
_______________________________________________

Solutions apportées :
_______________________________________________
_______________________________________________
_______________________________________________

---

> [!SUCCESS] Migration terminée 🎉
> Date de fin : _______________
