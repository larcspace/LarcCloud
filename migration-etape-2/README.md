# 🚀 Migration Étape 2 : Import des Données vers LarcCloud

Ce dossier contient tous les scripts nécessaires pour exporter les données de ta base locale de production (Django/PostgreSQL) et les importer dans ton projet Supabase Cloud (**LarcCloud**).

## 📋 Prérequis

1.  **PostgreSQL Client (`psql`)** installé et accessible dans le PATH.
2.  **Fichier `.pgpass`** configuré sur ton poste Windows pour éviter de saisir le mot de passe à chaque fois.
    *   Emplacement : `C:\Users\TON_UTILISATEUR\.pgpass`
    *   Contenu (une seule ligne) :
        ```text
        aws-1-eu-north-1.pooler.supabase.com:6543:postgres:postgres.TON_PROJECT_REF:TON_MOT_DE_PASSE_SIMPLE
        ```
    *   *Note : Utilise un mot de passe sans caractères spéciaux complexes pour éviter les bugs d'interprétation.*
3.  **Accès Réseau** : Ton adresse IP publique doit être autorisée dans le dashboard Supabase (Settings > Database > Network Restrictions).

---

## 🔄 Procédure Complète

### 1. Export des données locales (UTF-8)
Exécute le script d'export sur ta machine où tourne la base de production locale. Il générera des fichiers CSV encodés en **UTF-8** (requis par Supabase).

```cmd
01_export_utf8.bat
```
*Vérifie que le dossier `csv_export` contient bien 52 fichiers.*

### 2. Nettoyage de la base Cloud (Si nécessaire)
Si tu as tenté un import précédent qui a échoué ou partiellement réussi, vide d'abord toutes les tables dans Supabase.
*   Ouvre l'éditeur SQL du dashboard Supabase.
*   Copie-colle et exécute le contenu de `03_truncate_tables.sql`.

### 3. Import vers Supabase Cloud
Exécute le script d'import qui lit les CSV et les injecte dans le cloud.

```cmd
psql -h aws-1-eu-north-1.pooler.supabase.com -p 6543 -U postgres.TON_PROJECT_REF -d postgres -f 02_import_to_cloud.sql
```
*Remplace `TON_PROJECT_REF` par ton identifiant de projet.*

### 4. Activation des Triggers et Séquences (CRUCIAL)
Une fois l'import terminé, les triggers de synchronisation sont désactivés et les séquences (IDs) peuvent être désalignées.
*   Ouvre l'éditeur SQL du dashboard Supabase.
*   Copie-colle et exécute le contenu de `04_activate_triggers.sql`.

---

## 🛠️ Dépannage

*   **Erreur `invalid byte sequence for encoding "UTF8"`** : Tes fichiers CSV ne sont pas en UTF-8. Relance l'étape 1 avec le script corrigé.
*   **Erreur `password authentication failed`** : Vérifie ton fichier `.pgpass` ou utilise un mot de passe plus simple.
*   **Erreur `Connection timed out`** : Vérifie que ton IP est bien whitelistée dans Supabase.
