-- ============================================================
-- ACTIVATION DES TRIGGERS ET MISE À JOUR DES SÉQUENCES
-- À exécuter APRÈS l'import des données dans Supabase
-- ============================================================

-- 1. Réactiver tous les triggers de mise à jour et de log
DO $$
DECLARE
    r record;
    trigger_name text;
BEGIN
    FOREACH trigger_name IN ARRAY ARRAY['update_updated_at_column', 'update_sync_version', 'track_changes']
    LOOP
        FOR r IN (
            SELECT tablename 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename LIKE 'larcauth_%'
        ) LOOP
            IF EXISTS (
                SELECT 1 FROM pg_trigger 
                WHERE tgrelid = (SELECT oid FROM pg_class WHERE relname = r.tablename)
                AND tgname = trigger_name
            ) THEN
                EXECUTE format('ALTER TABLE %I ENABLE TRIGGER %I;', r.tablename, trigger_name);
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- 2. Mettre à jour les séquences (IDs) pour éviter les conflits futurs
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN (
        SELECT tablename, columnname
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name LIKE 'larcauth_%'
        AND column_default LIKE 'nextval%'
    ) LOOP
        BEGIN
            EXECUTE format(
                'SELECT setval(pg_get_serial_sequence(%L, %L), COALESCE((SELECT MAX(%I) FROM %I), 1), true);', 
                r.tablename, r.columnname, r.columnname, r.tablename
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erreur sequence %.% : %', r.tablename, r.columnname, SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. Vérification finale (Affiche l'état des triggers)
SELECT 
    t.tablename AS "Table",
    tg.tgname AS "Trigger",
    CASE WHEN tgenabled = 'O' THEN '✅ ACTIF' ELSE '❌ OFF' END AS "État"
FROM pg_trigger tg
JOIN pg_class tc ON tg.tgrelid = tc.oid
JOIN pg_tables t ON t.tablename = tc.relname
WHERE t.schemaname = 'public'
  AND t.tablename LIKE 'larcauth_%'
  AND tg.tgname IN ('update_updated_at_column', 'update_sync_version', 'track_changes')
ORDER BY t.tablename, tg.tgname;
