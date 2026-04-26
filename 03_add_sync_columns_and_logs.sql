-- ============================================================
-- LARC CLOUD : MIGRATION SYNC & LOGGING
-- ============================================================
-- Objectif : Préparer la base pour la synchro bidirectionnelle
-- 1. Ajout des colonnes de suivi (sync_version, synced_at, synced_by)
-- 2. Création de la table de logs centrale
-- 3. Installation des triggers automatiques
-- ============================================================

-- -------------------------------------------------------------
-- 1. CONFIGURATION : Fonction pour récupérer l'utilisateur actuel
-- -------------------------------------------------------------
-- Cette fonction lit une variable de session 'app.current_user_id'
-- Elle doit être appelée par votre application (Python/Delphi) avant chaque transaction
-- Ex: SET LOCAL app.current_user_id = 'user@larc.com';

CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS TEXT AS $$
BEGIN
    RETURN current_setting('app.current_user_id', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -------------------------------------------------------------
-- 2. TABLE DE LOGS CENTRALE
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.larcauth_sync_log (
    log_id BIGSERIAL PRIMARY KEY,
    log_timestamp TIMESTAMPTZ DEFAULT NOW(),
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL, -- ID de l'enregistrement modifié
    operation TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_data JSONB,          -- Données avant modification (NULL si INSERT)
    new_data JSONB,          -- Données après modification (NULL si DELETE)
    changed_by TEXT,         -- Email ou ID de l'utilisateur
    sync_version BIGINT,     -- Version de synchro après modif
    conflict_detected BOOLEAN DEFAULT FALSE,
    resolved BOOLEAN DEFAULT FALSE
);

-- Index pour accélérer les recherches de logs
CREATE INDEX IF NOT EXISTS idx_sync_log_table_record ON public.larcauth_sync_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_sync_log_timestamp ON public.larcauth_sync_log(log_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_sync_log_user ON public.larcauth_sync_log(changed_by);

COMMENT ON TABLE public.larcauth_sync_log IS 'Journal central de toutes les modifications pour la synchro et l''audit.';

-- -------------------------------------------------------------
-- 3. FONCTION TRIGGER GÉNÉRIQUE
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_track_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id TEXT;
    v_old_json JSONB;
    v_new_json JSONB;
    v_record_id TEXT;
    v_sync_ver BIGINT;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := get_current_user_id();
    
    -- Déterminer l'ID de l'enregistrement et les données
    IF TG_OP = 'DELETE' THEN
        v_record_id := OLD.id::TEXT;
        v_old_json := to_jsonb(OLD);
        v_new_json := NULL;
        v_sync_ver := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        v_record_id := NEW.id::TEXT;
        v_old_json := NULL;
        v_new_json := to_jsonb(NEW);
        v_sync_ver := NEW.sync_version;
    ELSIF TG_OP = 'UPDATE' THEN
        v_record_id := NEW.id::TEXT;
        v_old_json := to_jsonb(OLD);
        v_new_json := to_jsonb(NEW);
        v_sync_ver := NEW.sync_version;
        
        -- Si rien n'a changé techniquement, on ne loggue pas (optionnel)
        -- IF v_old_json IS NOT DISTINCT FROM v_new_json THEN
        --    RETURN NEW;
        -- END IF;
    END IF;

    -- Insérer dans le log
    INSERT INTO public.larcauth_sync_log (
        table_name, record_id, operation, old_data, new_data, changed_by, sync_version
    ) VALUES (
        TG_TABLE_NAME, v_record_id, TG_OP, v_old_json, v_new_json, v_user_id, v_sync_ver
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -------------------------------------------------------------
-- 4. FONCTION POUR METTRE À JOUR sync_version ET synced_at
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_update_sync_metadata()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id TEXT;
BEGIN
    -- Récupérer l'utilisateur
    v_user_id := get_current_user_id();

    -- Incrémenter la version de synchro
    NEW.sync_version := COALESCE(OLD.sync_version, 0) + 1;
    
    -- Mettre à jour la date
    NEW.synced_at := NOW();
    
    -- Mettre à jour l'utilisateur (si la colonne existe)
    -- Note: On utilise un bloc dynamique pour éviter l'erreur si la colonne n'existe pas sur certaines tables
    BEGIN
        EXECUTE format('SELECT $1.%I', 'synced_by') USING NEW;
        NEW.synced_by := v_user_id;
    EXCEPTION WHEN undefined_column THEN
        -- La colonne synced_by n'existe pas, on ignore
        NULL;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- 5. APPLICATION SUR LES TABLES
-- -------------------------------------------------------------
-- Liste des tables à modifier (basé sur le schéma fourni)
-- On exclut les tables de configuration pure qui changent rarement (ex: language, gender) si nécessaire,
-- mais ici on applique à TOUT pour être sûr.

DO $$
DECLARE
    tbl RECORD;
    col_def CONSTANT TEXT := 'sync_version BIGINT DEFAULT 0, synced_at TIMESTAMPTZ DEFAULT NOW(), synced_by TEXT';
    trigger_exists BOOLEAN;
BEGIN
    -- Boucle sur toutes les tables du schema public commençant par 'larcauth_'
    FOR tbl IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'larcauth_%'
        AND tablename NOT IN ('larcauth_sync_log') -- On exclut la table de log elle-même
    LOOP
        RAISE NOTICE 'Traitement de la table : %', tbl.tablename;

        -- 5.1 Ajouter les colonnes si elles n'existent pas déjà
        -- Vérification sync_version
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = tbl.tablename AND column_name = 'sync_version'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN sync_version BIGINT DEFAULT 0;', tbl.tablename);
        END IF;

        -- Vérification synced_at
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = tbl.tablename AND column_name = 'synced_at'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN synced_at TIMESTAMPTZ DEFAULT NOW();', tbl.tablename);
        END IF;

        -- Vérification synced_by
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = tbl.tablename AND column_name = 'synced_by'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN synced_by TEXT;', tbl.tablename);
        END IF;

        -- 5.2 Créer le trigger de mise à jour automatique (metadata)
        -- Nom du trigger : trk_update_metadata_<table>
        EXECUTE format('
            DROP TRIGGER IF EXISTS trk_update_metadata_%I ON public.%I;
            CREATE TRIGGER trk_update_metadata_%I
            BEFORE UPDATE ON public.%I
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_update_sync_metadata();
        ', tbl.tablename, tbl.tablename, tbl.tablename, tbl.tablename);

        -- 5.3 Créer le trigger de logging (insert/update/delete)
        -- Nom du trigger : trk_log_changes_<table>
        EXECUTE format('
            DROP TRIGGER IF EXISTS trk_log_changes_%I ON public.%I;
            CREATE TRIGGER trk_log_changes_%I
            AFTER INSERT OR UPDATE OR DELETE ON public.%I
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_track_changes();
        ', tbl.tablename, tbl.tablename, tbl.tablename, tbl.tablename);

    END LOOP;
END $$;

-- -------------------------------------------------------------
-- 6. VALIDATION & TEST
-- -------------------------------------------------------------
-- Affichage du nombre de tables traitées
DO $$
DECLARE
    cnt INTEGER;
BEGIN
    SELECT COUNT(*) INTO cnt 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename LIKE 'larcauth_%'
    AND tablename != 'larcauth_sync_log';
    
    RAISE NOTICE 'Migration terminée. % tables configurées pour la synchro et le logging.', cnt;
END $$;

-- -------------------------------------------------------------
-- 7. UTILISATION CÔTÉ APPLICATION (Rappel)
-- -------------------------------------------------------------
-- Avant chaque transaction importante dans votre code Python/Delphi :
-- 1. Connexion : psql.connect(...)
-- 2. Définir l'utilisateur : cursor.execute("SET LOCAL app.current_user_id = %s", ('prof@larc.com',))
-- 3. Exécuter vos UPDATE/INSERT
-- 4. Commit
-- Le trigger mettra à jour sync_version (+1), synced_at (now) et logged l'action.

COMMENT ON COLUMN public.larcauth_sync_log.old_data IS 'Snapshot JSON de l''enregistrement avant modification.';
COMMENT ON COLUMN public.larcauth_sync_log.new_data IS 'Snapshot JSON de l''enregistrement après modification.';
