-- =====================================================
-- PHASE 1 : Ajout des colonnes sync_version et updated_at
-- À exécuter sur chaque table gabarit dans Non-Prod
-- =====================================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    -- Incrémenter sync_version à chaque modification
    NEW.sync_version = COALESCE(OLD.sync_version, 0) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Exemple pour une table 'utilisateurs'
-- Adaptez le nom de table selon vos besoins
-- =====================================================

-- Ajouter les colonnes si elles n'existent pas
ALTER TABLE utilisateurs 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS sync_version INTEGER DEFAULT 0;

-- Mettre à jour les lignes existantes avec une valeur initiale
UPDATE utilisateurs SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE utilisateurs SET sync_version = 1 WHERE sync_version = 0;

-- Créer le trigger pour cette table
DROP TRIGGER IF EXISTS trg_utilisateurs_updated ON utilisateurs;
CREATE TRIGGER trg_utilisateurs_updated
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Répéter pour chaque table gabarit :
-- - projets
-- - documents
-- - etc.
-- =====================================================

-- Exemple générique (à adapter) :
-- ALTER TABLE nom_table ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
-- ALTER TABLE nom_table ADD COLUMN IF NOT EXISTS sync_version INTEGER DEFAULT 0;
-- CREATE TRIGGER trg_nom_table_updated BEFORE UPDATE ON nom_table FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TEST : Vérifier que le trigger fonctionne
-- =====================================================
-- UPDATE utilisateurs SET nom = 'test' WHERE id = 1;
-- SELECT sync_version FROM utilisateurs WHERE id = 1; -- Doit être incrémenté
