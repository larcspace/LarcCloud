--
-- LARC CLOUD - SCHÉMA COMPLET (50 Tables + Sync + Logs)
-- Généré pour migration Old Prod -> Supabase Cloud
--

-- 1. TYPE ENUMERÉ POUR LES STATUTS D'ACQUISITION
CREATE TYPE public.status_acquisition_type AS ENUM (
    'NA',
    'PA',
    'A',
    '-'
);

-- 2. TABLE DE LOG DE SYNCHRONISATION
CREATE TABLE public.larcauth_sync_log (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    old_data JSONB,
    new_data JSONB,
    changed_by INTEGER, -- ID de l'utilisateur (aecuser)
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    sync_version BIGINT DEFAULT 0
);

-- 3. FONCTION POUR RÉCUPÉRER L'UTILISATEUR CONNECTÉ (à adapter selon ton auth)
CREATE OR REPLACE FUNCTION public.get_current_user_id() RETURNS INTEGER AS $$
BEGIN
    -- Retourne NULL si pas d'utilisateur connecté (mode daemon ou admin)
    -- À adapter si tu utilises un système de rôle spécifique
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- 4. FONCTION TRIGGER POUR MISE À JOUR AUTOMATIQUE (Sync + Log)
CREATE OR REPLACE FUNCTION public.handle_sync_update() RETURNS TRIGGER AS $$
DECLARE
    user_id INTEGER;
    old_json JSONB;
    new_json JSONB;
BEGIN
    user_id := public.get_current_user_id();
    
    IF TG_OP = 'DELETE' THEN
        old_json := to_jsonb(OLD);
        new_json := NULL;
        INSERT INTO public.larcauth_sync_log (table_name, record_id, operation, old_data, new_data, changed_by, sync_version)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', old_json, new_json, user_id, COALESCE(OLD.sync_version, 0));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.sync_version := COALESCE(OLD.sync_version, 0) + 1;
        NEW.synced_at := NOW();
        NEW.synced_by := user_id;
        
        old_json := to_jsonb(OLD);
        new_json := to_jsonb(NEW);
        INSERT INTO public.larcauth_sync_log (table_name, record_id, operation, old_data, new_data, changed_by, sync_version)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', old_json, new_json, user_id, NEW.sync_version);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        NEW.sync_version := 1;
        NEW.synced_at := NOW();
        NEW.synced_by := user_id;
        
        new_json := to_jsonb(NEW);
        INSERT INTO public.larcauth_sync_log (table_name, record_id, operation, old_data, new_data, changed_by, sync_version)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', NULL, new_json, user_id, NEW.sync_version);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- CRÉATION DES 50 TABLES AVEC COLONNES DE SYNC INTÉGRÉES
-- ============================================================

-- Table: larcauth_academicyear
CREATE TABLE public.larcauth_academicyear (
    s_id smallint NOT NULL,
    label character varying(9) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    current_term_number smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    auto_calc boolean NOT NULL,
    debug_mode boolean NOT NULL,
    synchro_allowed boolean NOT NULL,
    "Current_unit_number" smallint DEFAULT 1,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_aecuser
CREATE TABLE public.larcauth_aecuser (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(30) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL,
    firstname_2 character varying(72),
    date_entree date,
    tel_maison character varying(20),
    tel_smartphone_1 character varying(20),
    tel_smartphone_2 character varying(20),
    emailperso character varying(254),
    passdelph character varying(20),
    avatar character varying(100) NOT NULL,
    picture2 bytea NOT NULL,
    type_parentutor boolean,
    type_teacher boolean,
    type_coordonator boolean,
    type_supervisor boolean,
    type_student boolean,
    type_director boolean,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_gender_id integer,
    fk_parent_id integer,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_agenda
CREATE TABLE public.larcauth_agenda (
    id integer NOT NULL,
    date_all date NOT NULL,
    j smallint DEFAULT 0 NOT NULL,
    m smallint DEFAULT 0 NOT NULL,
    w smallint DEFAULT 0 NOT NULL,
    year smallint DEFAULT 0 NOT NULL,
    year_week smallint DEFAULT 0,
    term smallint DEFAULT 0,
    term_week smallint DEFAULT 0,
    unit smallint DEFAULT 0,
    unit_week smallint DEFAULT 0,
    working_day boolean DEFAULT true,
    week_day smallint DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_campus
CREATE TABLE public.larcauth_campus (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(72) NOT NULL,
    adress character varying(255) NOT NULL,
    city character varying(72) NOT NULL,
    country character varying(2) NOT NULL,
    tel_1 character varying(12) NOT NULL,
    tel_2 character varying(12),
    email_1 character varying(254) NOT NULL,
    email_2 character varying(254),
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_district_id integer NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_classroom
CREATE TABLE public.larcauth_classroom (
    id integer NOT NULL,
    label character varying(33) NOT NULL,
    index_in_level smallint NOT NULL,
    description text NOT NULL,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_level_id integer NOT NULL,
    fk_headteacher_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_classroom_has_timeperiod
CREATE TABLE public.larcauth_classroom_has_timeperiod (
    id character varying(12) NOT NULL,
    fk_classroom integer,
    fk_weekday smallint,
    fk_timeperiod character varying,
    fk_term smallint,
    ref_classroom_termsubject integer,
    s_classroom_termsubject character varying(72),
    remarque character varying(255),
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_classroom_termothersubject
CREATE TABLE public.larcauth_classroom_termothersubject (
    id integer NOT NULL,
    label character varying(144) NOT NULL,
    description text NOT NULL,
    unit_multisubjects boolean NOT NULL,
    nb_subjects smallint,
    ref_unit_subject1 smallint,
    ref_unit_subject2 smallint,
    ref_unit_subject3 smallint,
    ref_unit_subject4 smallint,
    ref_unit_subject5 smallint,
    ref_unit_subject6 smallint,
    ref_unit_subject7 smallint,
    ref_unit_subject8 smallint,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_classroom_id integer NOT NULL,
    fk_term_id integer NOT NULL,
    fk_supervisor_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_classroom_termsubject
CREATE TABLE public.larcauth_classroom_termsubject (
    id integer NOT NULL,
    label character varying(72) NOT NULL,
    description text NOT NULL,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_classroom_id integer NOT NULL,
    fk_levelsubject_id integer NOT NULL,
    fk_term_id integer NOT NULL,
    fk_teacher_id integer NOT NULL,
    couleur character varying(10) NOT NULL,
    niv_sup boolean DEFAULT false,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_concept
CREATE TABLE public.larcauth_concept (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(36) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_criteria_of_levelsubject
CREATE TABLE public.larcauth_criteria_of_levelsubject (
    id integer NOT NULL,
    criteria_letter character varying(1) NOT NULL,
    criteria_label character varying(72) NOT NULL,
    criteria_description text NOT NULL,
    enabled boolean NOT NULL,
    aspects1nr smallint NOT NULL,
    aspect_11 character varying(222),
    aspect_12 character varying(222),
    aspect_13 character varying(222),
    aspect_14 character varying(222),
    aspect_15 character varying(222),
    aspect_16 character varying(222),
    aspect_17 character varying(222),
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_levelsubject_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_criteria_of_subjectsgroup
CREATE TABLE public.larcauth_criteria_of_subjectsgroup (
    id integer NOT NULL,
    criteria_letter character varying(1) NOT NULL,
    criteria_label character varying(72) NOT NULL,
    criteria_description text NOT NULL,
    enabled boolean NOT NULL,
    aspects1nr smallint NOT NULL,
    aspect_11 character varying(222),
    aspect_12 character varying(222),
    aspect_13 character varying(222),
    aspect_14 character varying(222),
    aspect_15 character varying(222),
    aspect_16 character varying(222),
    aspect_17 character varying(222),
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_subjectgroup_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_district
CREATE TABLE public.larcauth_district (
    id integer NOT NULL,
    label character varying(72) NOT NULL,
    sigle character varying(4) NOT NULL,
    arrondissement character varying(3),
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_edt_classe
CREATE TABLE public.larcauth_edt_classe (
    id character varying(12) NOT NULL,
    ressource_dow character varying(5),
    title character varying(255),
    text character varying(255),
    starttime time without time zone,
    endtime time without time zone,
    recurrency character varying(255),
    color smallint,
    fk_term smallint,
    fk_classroom integer,
    fk_timeperiod character varying(7),
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_evaluation
CREATE TABLE public.larcauth_evaluation (
    id bigint NOT NULL,
    label character varying(3) NOT NULL,
    nature character varying(72),
    "baremeNoteDP" smallint NOT NULL,
    type_evaluation character varying(1) NOT NULL,
    index_eval smallint NOT NULL,
    crit_a boolean,
    aspect_a1 boolean,
    aspect_a2 boolean,
    aspect_a3 boolean,
    aspect_a4 boolean,
    aspect_a5 boolean,
    aspect_a6 boolean,
    aspect_a7 boolean,
    crit_b boolean,
    aspect_b1 boolean,
    aspect_b2 boolean,
    aspect_b3 boolean,
    aspect_b4 boolean,
    aspect_b5 boolean,
    aspect_b6 boolean,
    aspect_b7 boolean,
    crit_c boolean,
    aspect_c1 boolean,
    aspect_c2 boolean,
    aspect_c3 boolean,
    aspect_c4 boolean,
    aspect_c5 boolean,
    aspect_c6 boolean,
    aspect_c7 boolean,
    crit_d boolean,
    aspect_d1 boolean,
    aspect_d2 boolean,
    aspect_d3 boolean,
    aspect_d4 boolean,
    aspect_d5 boolean,
    aspect_d6 boolean,
    aspect_d7 boolean,
    crit_e boolean,
    aspect_e1 boolean,
    aspect_e2 boolean,
    aspect_e3 boolean,
    aspect_e4 boolean,
    aspect_e5 boolean,
    aspect_e6 boolean,
    aspect_e7 boolean,
    "crit_F" boolean,
    aspect_f1 boolean,
    aspect_f2 boolean,
    aspect_f3 boolean,
    aspect_f4 boolean,
    aspect_f5 boolean,
    aspect_f6 boolean,
    aspect_f7 boolean,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_classroom_termsubject_id integer NOT NULL,
    "baremeNoteCritere" smallint NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_gender
CREATE TABLE public.larcauth_gender (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(12) NOT NULL,
    sigle character varying(4) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_globalcontext
CREATE TABLE public.larcauth_globalcontext (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(55) NOT NULL,
    description text NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_language
CREATE TABLE public.larcauth_language (
    id integer NOT NULL,
    sigle character varying(2) NOT NULL,
    label character varying(15) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learner_has_subjectgroup
CREATE TABLE public.larcauth_learner_has_subjectgroup (
    id integer NOT NULL,
    note_on_7 smallint,
    sum_on_7 smallint,
    average_on_7 smallint,
    description character varying(1500) NOT NULL,
    enabled boolean NOT NULL,
    validated boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_subjectgroup_id integer NOT NULL,
    fk_term_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learner_has_term
CREATE TABLE public.larcauth_learner_has_term (
    id integer NOT NULL,
    term_mark_on_56 smallint,
    term_mark_on_45 smallint,
    term_eetdc_bonus smallint,
    observation_global text,
    observation_profil text,
    term_average_global_on_20 double precision,
    enabled boolean NOT NULL,
    validated boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_term_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    term_subject_choice_ok boolean NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learner_has_termothersubject
CREATE TABLE public.larcauth_learner_has_termothersubject (
    id integer NOT NULL,
    titre character varying(144) NOT NULL,
    bareme smallint,
    mark_on_bareme double precision,
    mark_on_20 double precision,
    mark_on_letter character varying(1),
    observation_global text,
    observation_target character varying(144) NOT NULL,
    os_note_a smallint,
    os_note_b smallint,
    os_note_c smallint,
    os_note_d smallint,
    os_note_e smallint,
    os_note_f smallint,
    os_observation character varying(1500),
    enabled boolean NOT NULL,
    validated boolean NOT NULL,
    ref_teacher_used boolean NOT NULL,
    ref_teacher smallint,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_termothersubject_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learner_has_termsubject
CREATE TABLE public.larcauth_learner_has_termsubject (
    id integer NOT NULL,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_classroom_termsubject_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnerdp_has_termsubjectdp
CREATE TABLE public.larcauth_learnerdp_has_termsubjectdp (
    learner_has_termsubject_ptr_id integer NOT NULL,
    f01_observation character varying(360),
    f02_observation character varying(360),
    f03_observation character varying(360),
    f04_observation character varying(360),
    f05_observation character varying(360),
    f06_observation character varying(360),
    f07_observation character varying(360),
    f08_observation character varying(360),
    f09_observation character varying(360),
    f10_observation character varying(360),
    f11_observation character varying(360),
    f12_observation character varying(360),
    s01_observation character varying(360),
    s02_observation character varying(360),
    s03_observation character varying(360),
    s04_observation character varying(360),
    s05_observation character varying(360),
    s06_observation character varying(360),
    s07_observation character varying(360),
    s08_observation character varying(360),
    s09_observation character varying(360),
    s10_observation character varying(360),
    s11_observation character varying(360),
    s12_observation character varying(360),
    f01_note double precision,
    f01_note_a smallint,
    f01_note_b smallint,
    f01_note_c smallint,
    f01_note_d smallint,
    f01_note_e smallint,
    f01_note_f smallint,
    f02_note double precision,
    f02_note_a smallint,
    f02_note_b smallint,
    f02_note_c smallint,
    f02_note_d smallint,
    f02_note_e smallint,
    f02_note_f smallint,
    f03_note double precision,
    f03_note_a smallint,
    f03_note_b smallint,
    f03_note_c smallint,
    f03_note_d smallint,
    f03_note_e smallint,
    f03_note_f smallint,
    f04_note double precision,
    f04_note_a smallint,
    f04_note_b smallint,
    f04_note_c smallint,
    f04_note_d smallint,
    f04_note_e smallint,
    f04_note_f smallint,
    f05_note double precision,
    f05_note_a smallint,
    f05_note_b smallint,
    f05_note_c smallint,
    f05_note_d smallint,
    f05_note_e smallint,
    f05_note_f smallint,
    f06_note double precision,
    f06_note_a smallint,
    f06_note_b smallint,
    f06_note_c smallint,
    f06_note_d smallint,
    f06_note_e smallint,
    f06_note_f smallint,
    f07_note double precision,
    f07_note_a smallint,
    f07_note_b smallint,
    f07_note_c smallint,
    f07_note_d smallint,
    f07_note_e smallint,
    f07_note_f smallint,
    f08_note double precision,
    f08_note_a smallint,
    f08_note_b smallint,
    f08_note_c smallint,
    f08_note_d smallint,
    f08_note_e smallint,
    f08_note_f smallint,
    f09_note double precision,
    f09_note_a smallint,
    f09_note_b smallint,
    f09_note_c smallint,
    f09_note_d smallint,
    f09_note_e smallint,
    f09_note_f smallint,
    f10_note double precision,
    f10_note_a smallint,
    f10_note_b smallint,
    f10_note_c smallint,
    f10_note_d smallint,
    f10_note_e smallint,
    f10_note_f smallint,
    f11_note double precision,
    f11_note_a smallint,
    f11_note_b smallint,
    f11_note_c smallint,
    f11_note_d smallint,
    f11_note_e smallint,
    f11_note_f smallint,
    f12_note double precision,
    f12_note_a smallint,
    f12_note_b smallint,
    f12_note_c smallint,
    f12_note_d smallint,
    f12_note_e smallint,
    f12_note_f smallint,
    s01_note double precision,
    s01_note_a smallint,
    s01_note_b smallint,
    s01_note_c smallint,
    s01_note_d smallint,
    s01_note_e smallint,
    s01_note_f smallint,
    s02_note double precision,
    s02_note_a smallint,
    s02_note_b smallint,
    s02_note_c smallint,
    s02_note_d smallint,
    s02_note_e smallint,
    s02_note_f smallint,
    s03_note double precision,
    s03_note_a smallint,
    s03_note_b smallint,
    s03_note_c smallint,
    s03_note_d smallint,
    s03_note_e smallint,
    s03_note_f smallint,
    s04_note double precision,
    s04_note_a smallint,
    s04_note_b smallint,
    s04_note_c smallint,
    s04_note_d smallint,
    s04_note_e smallint,
    s04_note_f smallint,
    s05_note double precision,
    s05_note_a smallint,
    s05_note_b smallint,
    s05_note_c smallint,
    s05_note_d smallint,
    s05_note_e smallint,
    s05_note_f smallint,
    s06_note double precision,
    s06_note_a smallint,
    s06_note_b smallint,
    s06_note_c smallint,
    s06_note_d smallint,
    s06_note_e smallint,
    s06_note_f smallint,
    s07_note double precision,
    s07_note_a smallint,
    s07_note_b smallint,
    s07_note_c smallint,
    s07_note_d smallint,
    s07_note_e smallint,
    s07_note_f smallint,
    s08_note double precision,
    s08_note_a smallint,
    s08_note_b smallint,
    s08_note_c smallint,
    s08_note_d smallint,
    s08_note_e smallint,
    s08_note_f smallint,
    s09_note double precision,
    s09_note_a smallint,
    s09_note_b smallint,
    s09_note_c smallint,
    s09_note_d smallint,
    s09_note_e smallint,
    s09_note_f smallint,
    s10_note double precision,
    s10_note_a smallint,
    s10_note_b smallint,
    s10_note_c smallint,
    s10_note_d smallint,
    s10_note_e smallint,
    s10_note_f smallint,
    s11_note double precision,
    s11_note_a smallint,
    s11_note_b smallint,
    s11_note_c smallint,
    s11_note_d smallint,
    s11_note_e smallint,
    s11_note_f smallint,
    s12_note double precision,
    s12_note_a smallint,
    s12_note_b smallint,
    s12_note_c smallint,
    s12_note_d smallint,
    s12_note_e smallint,
    s12_note_f smallint,
    cp_note double precision,
    cp_note_a smallint,
    cp_note_b smallint,
    cp_note_c smallint,
    cp_note_d smallint,
    cp_note_e smallint,
    cp_note_f smallint,
    jgt_a smallint,
    jgt_b smallint,
    jgt_c smallint,
    jgt_d smallint,
    jgt_e smallint,
    jgt_f smallint,
    ei_note double precision,
    ei_observation character varying(2000),
    ei_objectif character varying(250),
    cpei double precision,
    cc_on_20 double precision,
    moy_on_20 double precision,
    moy_on_7 double precision,
    bacblanc_v double precision,
    bacblanc smallint,
    term_observation text,
    cp_observation character varying(360),
    f13_obsersation character varying(360),
    f14_obsersation character varying(360),
    f15_obsersation character varying(360),
    jgt_obsersation character varying(1200),
    s13_note double precision,
    s13_note_a smallint,
    s13_note_b smallint,
    s13_note_c smallint,
    s13_note_d smallint,
    s13_note_e smallint,
    s13_note_f smallint,
    s13_observation character varying(720),
    s14_note double precision,
    s14_note_a smallint,
    s14_note_b smallint,
    s14_note_c smallint,
    s14_note_d smallint,
    s14_note_e smallint,
    s14_note_f smallint,
    s14_observation character varying(360),
    s15_note double precision,
    s15_note_a smallint,
    s15_note_b smallint,
    s15_note_c smallint,
    s15_note_d smallint,
    s15_note_e smallint,
    s15_note_f smallint,
    s15_observation character varying(1200),
    bacblanc2 smallint,
    bacblanc_v2 double precision,
    f13_note double precision,
    f13_note_a smallint[],
    f13_note_b smallint[],
    f13_note_c smallint[],
    f13_note_d smallint[],
    f13_note_e smallint[],
    f13_note_f smallint[],
    f14_note double precision[],
    f14_note_a smallint[],
    f14_note_b smallint[],
    f14_note_c smallint[],
    f14_note_d smallint[],
    f14_note_e smallint[],
    f14_note_f smallint[],
    f15_note double precision[],
    f15_note_a smallint[],
    f15_note_b smallint[],
    f15_note_c smallint[],
    f15_note_d smallint[],
    f15_note_e smallint[],
    f15_note_f smallint[],
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnermat_has_devpers_unit
CREATE TABLE public.larcauth_learnermat_has_devpers_unit (
    id integer NOT NULL,
    fk_student_id integer NOT NULL,
    fk_devpers_unit_id integer NOT NULL,
    enabled boolean DEFAULT false,
    ref_unit_nr integer NOT NULL,
    status public.status_acquisition_type,
    a boolean,
    pa boolean,
    na boolean,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnermat_has_subjectevals_unit
CREATE TABLE public.larcauth_learnermat_has_subjectevals_unit (
    id integer NOT NULL,
    fk_student_id integer NOT NULL,
    fk_subjectevals_unit_id integer NOT NULL,
    disabled boolean DEFAULT false,
    enabled boolean DEFAULT false,
    ref_unit_nr integer NOT NULL,
    status public.status_acquisition_type,
    a boolean,
    pa boolean,
    na boolean,
    value smallint DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnermat_has_unit_period
CREATE TABLE public.larcauth_learnermat_has_unit_period (
    id integer NOT NULL,
    observation_global text,
    observation_profil text,
    unit_average_global_on_20 double precision,
    enabled boolean NOT NULL,
    validated boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_unit_period_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    b0_devpers boolean DEFAULT true NOT NULL,
    b1_langue boolean DEFAULT true NOT NULL,
    b2_math boolean DEFAULT true,
    b3_explore boolean DEFAULT true NOT NULL,
    b4_sport boolean DEFAULT true NOT NULL,
    b5_arts boolean DEFAULT true NOT NULL,
    note_lang_cat1 character varying(2) DEFAULT '-',
    note_lang_cat2 character varying(2) DEFAULT '-' NOT NULL,
    note_lang_cat3 character varying(2) DEFAULT '-' NOT NULL,
    note_lang_cat4 character varying(2) DEFAULT '-' NOT NULL,
    note2_math_cat1 character varying(2) DEFAULT '-' NOT NULL,
    note2_math_cat2 character varying(2) DEFAULT '-' NOT NULL,
    note2_math_cat3 character varying(2) DEFAULT '-' NOT NULL,
    note2_math_cat4 character varying(2) DEFAULT '-' NOT NULL,
    note3_expl_cat1 character varying(2) DEFAULT '-' NOT NULL,
    note3_expl_cat2 character varying(2) DEFAULT '-' NOT NULL,
    note3_expl_cat3 character varying(2) DEFAULT '-' NOT NULL,
    note3_expl_cat4 character varying(2) DEFAULT '-' NOT NULL,
    note4_arts_cat1 character varying(2) DEFAULT '-' NOT NULL,
    note4_arts_cat2 character varying(2) DEFAULT '-' NOT NULL,
    note4_arts_cat3 character varying(2) DEFAULT '-' NOT NULL,
    note4_arts_cat4 character varying(2) DEFAULT '-' NOT NULL,
    note5_phys_cat1 character varying(2) DEFAULT '-' NOT NULL,
    note5_phys_cat2 character varying(2) DEFAULT '-' NOT NULL,
    note5_phys_cat3 character varying(2) DEFAULT '-' NOT NULL,
    note5_phys_cat4 character varying(2) DEFAULT '-' NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnerpei_has_termsubjectpei
CREATE TABLE public.larcauth_learnerpei_has_termsubjectpei (
    learner_has_termsubject_ptr_id integer NOT NULL,
    f01_observation character varying(360),
    f02_observation character varying(360),
    f03_observation character varying(360),
    f04_observation character varying(360),
    f05_observation character varying(360),
    f06_observation character varying(360),
    f07_observation character varying(360),
    f08_observation character varying(360),
    f09_observation character varying(360),
    f10_observation character varying(360),
    f11_observation character varying(360),
    f12_observation character varying(360),
    s01_observation character varying(360),
    s02_observation character varying(360),
    s03_observation character varying(360),
    s04_observation character varying(360),
    s05_observation character varying(360),
    s06_observation character varying(360),
    s07_observation character varying(360),
    s08_observation character varying(360),
    s09_observation character varying(360),
    s10_observation character varying(360),
    s11_observation character varying(360),
    s12_observation character varying(360),
    f01_note_a smallint,
    f01_note_b smallint,
    f01_note_c smallint,
    f01_note_d smallint,
    f01_note_e smallint,
    f01_note_f smallint,
    f02_note_a smallint,
    f02_note_b smallint,
    f02_note_c smallint,
    f02_note_d smallint,
    f02_note_e smallint,
    f02_note_f smallint,
    f03_note_a smallint,
    f03_note_b smallint,
    f03_note_c smallint,
    f03_note_d smallint,
    f03_note_e smallint,
    f03_note_f smallint,
    f04_note_a smallint,
    f04_note_b smallint,
    f04_note_c smallint,
    f04_note_d smallint,
    f04_note_e smallint,
    f04_note_f smallint,
    f05_note_a smallint,
    f05_note_b smallint,
    f05_note_c smallint,
    f05_note_d smallint,
    f05_note_e smallint,
    f05_note_f smallint,
    f06_note_a smallint,
    f06_note_b smallint,
    f06_note_c smallint,
    f06_note_d smallint,
    f06_note_e smallint,
    f06_note_f smallint,
    f07_note_a smallint,
    f07_note_b smallint,
    f07_note_c smallint,
    f07_note_d smallint,
    f07_note_e smallint,
    f07_note_f smallint,
    f08_note_a smallint,
    f08_note_b smallint,
    f08_note_c smallint,
    f08_note_d smallint,
    f08_note_e smallint,
    f08_note_f smallint,
    f09_note_a smallint,
    f09_note_b smallint,
    f09_note_c smallint,
    f09_note_d smallint,
    f09_note_e smallint,
    f09_note_f smallint,
    f10_note_a smallint,
    f10_note_b smallint,
    f10_note_c smallint,
    f10_note_d smallint,
    f10_note_e smallint,
    f10_note_f smallint,
    f11_note_a smallint,
    f11_note_b smallint,
    f11_note_c smallint,
    f11_note_d smallint,
    f11_note_e smallint,
    f11_note_f smallint,
    f12_note_a smallint,
    f12_note_b smallint,
    f12_note_c smallint,
    f12_note_d smallint,
    f12_note_e smallint,
    f12_note_f smallint,
    s01_note_a smallint,
    s01_note_b smallint,
    s01_note_c smallint,
    s01_note_d smallint,
    s01_note_e smallint,
    s01_note_f smallint,
    s02_note_a smallint,
    s02_note_b smallint,
    s02_note_c smallint,
    s02_note_d smallint,
    s02_note_e smallint,
    s02_note_f smallint,
    s03_note_a smallint,
    s03_note_b smallint,
    s03_note_c smallint,
    s03_note_d smallint,
    s03_note_e smallint,
    s03_note_f smallint,
    s04_note_a smallint,
    s04_note_b smallint,
    s04_note_c smallint,
    s04_note_d smallint,
    s04_note_e smallint,
    s04_note_f smallint,
    s05_note_a smallint,
    s05_note_b smallint,
    s05_note_c smallint,
    s05_note_d smallint,
    s05_note_e smallint,
    s05_note_f smallint,
    s06_note_a smallint,
    s06_note_b smallint,
    s06_note_c smallint,
    s06_note_d smallint,
    s06_note_e smallint,
    s06_note_f smallint,
    s07_note_a smallint,
    s07_note_b smallint,
    s07_note_c smallint,
    s07_note_d smallint,
    s07_note_e smallint,
    s07_note_f smallint,
    s08_note_a smallint,
    s08_note_b smallint,
    s08_note_c smallint,
    s08_note_d smallint,
    s08_note_e smallint,
    s08_note_f smallint,
    s09_note_a smallint,
    s09_note_b smallint,
    s09_note_c smallint,
    s09_note_d smallint,
    s09_note_e smallint,
    "S09_note_f" smallint,
    s10_note_a smallint,
    s10_note_b smallint,
    s10_note_c smallint,
    s10_note_d smallint,
    s10_note_e smallint,
    s10_note_f smallint,
    s11_note_a smallint,
    s11_note_b smallint,
    s11_note_c smallint,
    s11_note_d smallint,
    s11_note_e smallint,
    s11_note_f smallint,
    s12_note_a smallint,
    s12_note_b smallint,
    s12_note_c smallint,
    s12_note_d smallint,
    s12_note_e smallint,
    s12_note_f smallint,
    s12_note_g smallint,
    cp_note_a smallint,
    cp_note_b smallint,
    cp_note_c smallint,
    cp_note_d smallint,
    cp_note_e smallint,
    cp_note_f smallint,
    cp_observation character varying(72),
    jgt_a smallint,
    jgt_b smallint,
    jgt_c smallint,
    jgt_d smallint,
    jgt_e smallint,
    jgt_f smallint,
    note_on_7 smallint,
    term_observation text,
    f13_obsersation character varying(360),
    f14_obsersation character varying(360),
    f15_obsersation character varying(360),
    s13_note_a smallint,
    s13_note_b smallint,
    s13_note_c smallint,
    s13_note_d smallint,
    s13_note_e smallint,
    s13_note_f smallint,
    s13_observation character varying(360),
    s14_note_a smallint,
    s14_note_b smallint,
    s14_note_c smallint,
    s14_note_d smallint,
    s14_note_e smallint,
    s14_note_f smallint,
    s14_observation character varying(360),
    s15_note_a smallint,
    s15_note_b smallint,
    s15_note_c smallint,
    s15_note_d smallint,
    s15_note_e smallint,
    s15_note_f smallint,
    s15_observation character varying(3000),
    f13_note_a smallint,
    f13_note_b smallint,
    f13_note_c smallint,
    f13_note_d smallint,
    f13_note_e smallint,
    f13_note_f smallint,
    f14_note_a smallint,
    f14_note_b smallint,
    f14_note_c smallint,
    f14_note_d smallint,
    f14_note_e smallint,
    f14_note_f smallint,
    f15_note_a smallint,
    f15_note_b smallint,
    f15_note_c smallint,
    f15_note_d smallint,
    f15_note_e smallint,
    f15_note_f smallint,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnerpp_has_termsubjectpp
CREATE TABLE public.larcauth_learnerpp_has_termsubjectpp (
    learner_has_termsubject_ptr_id integer NOT NULL,
    f01_observation character varying(360),
    f02_observation character varying(360),
    f03_observation character varying(360),
    f04_observation character varying(360),
    f05_observation character varying(360),
    f06_observation character varying(360),
    s01_observation character varying(360),
    s02_observation character varying(360),
    s03_observation character varying(360),
    s04_observation character varying(360),
    s05_observation character varying(360),
    s06_observation character varying(360),
    f01_note double precision,
    f01_note_a smallint,
    f01_note_b smallint,
    f01_note_c smallint,
    f01_note_d smallint,
    f02_note double precision,
    f02_note_a smallint,
    f02_note_b smallint,
    f02_note_c smallint,
    f02_note_d smallint,
    f03_note double precision,
    f03_note_a smallint,
    f03_note_b smallint,
    f03_note_c smallint,
    f03_note_d smallint,
    f04_note double precision,
    f04_note_a smallint,
    f04_note_b smallint,
    f04_note_c smallint,
    f04_note_d smallint,
    s01_note double precision,
    s01_note_a smallint,
    s01_note_b smallint,
    s01_note_c smallint,
    s01_note_d smallint,
    s02_note double precision,
    s02_note_a smallint,
    s02_note_b smallint,
    s02_note_c smallint,
    s02_note_d smallint,
    s03_note double precision,
    s03_note_a smallint,
    s03_note_b smallint,
    s03_note_c smallint,
    s03_note_d smallint,
    s04_note double precision,
    s04_note_a smallint,
    s04_note_b smallint,
    s04_note_c smallint,
    s04_note_d smallint,
    s05_note double precision,
    s05_note_a smallint,
    s05_note_b smallint,
    s05_note_c smallint,
    s05_note_d smallint,
    s06_note double precision,
    s06_note_a smallint,
    s06_note_b smallint,
    s06_note_c smallint,
    s06_note_d smallint,
    cp_note double precision,
    jgt_a smallint,
    jgt_b smallint,
    jgt_c smallint,
    jgt_d smallint,
    note_unit1 smallint,
    note_unit2 smallint,
    note_unit3 smallint,
    note_unit4 smallint,
    note_unit5 smallint,
    note_unit6 smallint,
    note_for_term smallint,
    term_observation text,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_learnerprim_has_unit_period
CREATE TABLE public.larcauth_learnerprim_has_unit_period (
    id integer NOT NULL,
    unit_mark_on_max smallint,
    unit_eetdc_bonus smallint,
    observation_global text,
    observation_profil text,
    unit_average_global_on_20 double precision,
    enabled boolean NOT NULL,
    validated boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_unit_period_id integer NOT NULL,
    fk_student_id integer NOT NULL,
    b_la boolean DEFAULT true NOT NULL,
    b_lb boolean DEFAULT true,
    b_ma boolean DEFAULT true NOT NULL,
    b_sc boolean DEFAULT true NOT NULL,
    b_hu boolean DEFAULT true NOT NULL,
    b_ar boolean DEFAULT true NOT NULL,
    b_sp boolean DEFAULT true NOT NULL,
    b_tr boolean DEFAULT true NOT NULL,
    f_la_a smallint,
    f_la_b smallint,
    f_la_c smallint,
    f_la_d smallint,
    f_la smallint,
    f_lb_a smallint,
    f_lb_b smallint,
    f_lb_c smallint,
    f_lb_d smallint,
    f_lb smallint,
    f_ma_a smallint,
    f_ma_b smallint,
    f_ma_c smallint,
    f_ma_d smallint,
    f_ma smallint,
    f_sc smallint,
    f_hu smallint,
    f_sp smallint,
    f_ar smallint,
    f_tr smallint,
    s_la_a smallint,
    s_la_b smallint,
    s_la_c smallint,
    s_la_d smallint,
    s_la smallint,
    s_lb_a smallint,
    s_lb_b smallint,
    s_lb_c smallint,
    s_lb_d smallint,
    s_lb smallint,
    s_ma_a smallint,
    s_ma_b smallint,
    s_ma_c smallint,
    s_ma_d smallint,
    s_ma smallint,
    s_sc smallint,
    s_hu smallint,
    s_sp smallint,
    s_ar smallint,
    s_tr smallint,
    nb_mat smallint DEFAULT 0 NOT NULL,
    note_on_max smallint DEFAULT 0 NOT NULL,
    unit_comment text,
    unit_profil_comment text,
    c_la character varying(3000),
    c_lb character varying(3000),
    c_ma character varying(3000),
    c_sc character varying(3000),
    c_hu character varying(3000),
    c_sp character varying(3000),
    c_ar character varying(3000),
    c_tr character varying(3000),
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_level
CREATE TABLE public.larcauth_level (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(33) NOT NULL,
    description text NOT NULL,
    level_in_pgm smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    fk_program_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_levelsubject
CREATE TABLE public.larcauth_levelsubject (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(55) NOT NULL,
    description text NOT NULL,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    fk_level_id integer NOT NULL,
    fk_subjectgroup_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_lieu
CREATE TABLE public.larcauth_lieu (
    "IDLieu" smallint NOT NULL,
    "s_IDLieu" smallint NOT NULL,
    "Lieu" character varying(72) NOT NULL,
    fk_language smallint NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_devpers_gene
CREATE TABLE public.larcauth_mat_devpers_gene (
    s_id integer NOT NULL,
    leveldevpers smallint DEFAULT 0,
    skillcategory character varying(144),
    skill character varying(144),
    skillactivity character varying(144),
    enabled boolean DEFAULT false,
    fk_language_id integer,
    pk_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_devpers_unit
CREATE TABLE public.larcauth_mat_devpers_unit (
    pk_id integer NOT NULL,
    leveldevpers smallint DEFAULT 0,
    skillcategory character varying(72),
    skill character varying(72),
    skillactivity character varying(72),
    enabled boolean DEFAULT false,
    fk_unit_period integer,
    s_id integer,
    "ref_Language" integer,
    ref_unit_nr smallint DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_subjectevals_unit
CREATE TABLE public.larcauth_mat_subjectevals_unit (
    id integer NOT NULL,
    label character varying(72),
    skillcategory character varying(72),
    skill_category integer,
    skill_evaluated integer,
    enabled boolean DEFAULT false,
    validated boolean DEFAULT false,
    date_eval date,
    date_valid date,
    ref_unit_nr smallint DEFAULT 0,
    fk_classroom_id integer,
    fk_unit_period integer,
    ref_test_nr integer,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_subjectskills
CREATE TABLE public.larcauth_mat_subjectskills (
    s_id integer NOT NULL,
    levelsubjeskill smallint DEFAULT 0,
    skillsubject character varying(144),
    skillcat character varying(144),
    subjectskill character varying(144),
    enabled boolean DEFAULT false,
    fk_language_id integer,
    pk_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_subjectskills_unit
CREATE TABLE public.larcauth_mat_subjectskills_unit (
    pk_id integer NOT NULL,
    levelsubjectskill smallint DEFAULT 0,
    skillsubject character varying(72),
    skillcat character varying(72),
    subjectskill character varying(72),
    enabled boolean DEFAULT false,
    fk_unit_period integer,
    s_id integer,
    "ref_Language" integer,
    ref_unit_nr smallint DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_mat_unit
CREATE TABLE public.larcauth_mat_unit (
    id integer NOT NULL,
    label character varying(10) NOT NULL,
    title character varying(144) NOT NULL,
    soi character varying(250) NOT NULL,
    loi character varying(250) NOT NULL,
    date_start date,
    date_end date,
    duration character varying(55),
    content character varying(255),
    finaltask character varying(255),
    details text NOT NULL,
    fk_relconcept1 smallint DEFAULT 0,
    fk_relconcept2 smallint DEFAULT 0,
    fk_relconcept3 smallint DEFAULT 0,
    fk_relconcept4 smallint DEFAULT 0,
    id_order_in_year smallint NOT NULL,
    fk_classroom_id integer NOT NULL,
    fk_globalcontext_id integer DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_natureparentutor
CREATE TABLE public.larcauth_natureparentutor (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(10) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_program
CREATE TABLE public.larcauth_program (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    sigle character varying(4) NOT NULL,
    label character varying(55) NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_student
CREATE TABLE public.larcauth_student (
    aecuser_ptr_id integer NOT NULL,
    aec_id character varying(12) NOT NULL,
    enabled boolean NOT NULL,
    created_s timestamp with time zone NOT NULL,
    updated_s timestamp with time zone NOT NULL,
    s_classroom_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_student_has_dayevents
CREATE TABLE public.larcauth_student_has_dayevents (
    id bigint NOT NULL,
    nbre_absence smallint NOT NULL,
    nbre_retards smallint NOT NULL,
    nbre_sorties smallint NOT NULL,
    nbre_comportements smallint NOT NULL,
    nbre_profil smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_student_id bigint NOT NULL,
    fk_day_id bigint NOT NULL,
    "Absence" boolean DEFAULT false NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_student_has_events
CREATE TABLE public.larcauth_student_has_events (
    id bigint NOT NULL,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_jour_id bigint NOT NULL,
    fk_student_id bigint NOT NULL,
    fk_typeevent_id smallint DEFAULT 0,
    ref_staff bigint NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_student_has_termevents
CREATE TABLE public.larcauth_student_has_termevents (
    id bigint NOT NULL,
    nbre_absence smallint NOT NULL,
    nbre_retards smallint NOT NULL,
    nbre_sorties smallint NOT NULL,
    nbre_comportements smallint NOT NULL,
    nbre_profil smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_student_id bigint NOT NULL,
    fk_term_id smallint NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_student_has_weekevents
CREATE TABLE public.larcauth_student_has_weekevents (
    id bigint NOT NULL,
    nbre_absence smallint NOT NULL,
    nbre_retards smallint NOT NULL,
    nbre_sorties smallint NOT NULL,
    nbre_comportements smallint NOT NULL,
    nbre_profil smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_student_id bigint NOT NULL,
    fk_term_id smallint NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_subjectgroup
CREATE TABLE public.larcauth_subjectgroup (
    id integer NOT NULL,
    s_id smallint NOT NULL,
    label character varying(44) NOT NULL,
    description text NOT NULL,
    nr_group_in_pgm smallint NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    fk_program_id integer NOT NULL,
    fk_coordonator_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_teachadm
CREATE TABLE public.larcauth_teachadm (
    aecuser_ptr_id integer NOT NULL,
    is_teacher boolean NOT NULL,
    is_adm boolean NOT NULL,
    is_coordonator boolean NOT NULL,
    is_secretary boolean NOT NULL,
    enabled boolean NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_term
CREATE TABLE public.larcauth_term (
    id integer NOT NULL,
    "trim" smallint NOT NULL,
    label character varying(15) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_termsubject_has_homework
CREATE TABLE public.larcauth_termsubject_has_homework (
    id integer NOT NULL,
    time_1 time without time zone,
    nature_1 character varying(72),
    todo_1 text,
    time_2 time without time zone,
    nature_2 character varying(72),
    todo_2 text,
    time_3 time without time zone,
    nature_3 character varying(72),
    todo_3 text,
    enabled boolean NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_classroom_termsubject_id integer NOT NULL,
    fk_jour_id integer,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_timeperiod
CREATE TABLE public.larcauth_timeperiod (
    id character varying(6) NOT NULL,
    debut time without time zone,
    fin time without time zone,
    weekday smallint,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_type_event
CREATE TABLE public.larcauth_type_event (
    idtypeevent smallint NOT NULL,
    type_event character varying(72),
    "Event_Niveau2" character varying(72),
    "Event_Niveau3" character varying(72),
    "Enabled" boolean DEFAULT false,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_unit
CREATE TABLE public.larcauth_unit (
    id integer NOT NULL,
    label character varying(10) NOT NULL,
    title character varying(144) NOT NULL,
    soi character varying(250) NOT NULL,
    loi character varying(250) NOT NULL,
    date_start date,
    date_end date,
    duration character varying(55),
    content character varying(255),
    finaltask character varying(255),
    details text NOT NULL,
    "crit_A" boolean DEFAULT false NOT NULL,
    "aspect_A1" boolean DEFAULT false NOT NULL,
    "aspect_A2" boolean DEFAULT false NOT NULL,
    "aspect_A3" boolean DEFAULT false NOT NULL,
    "aspect_A4" boolean DEFAULT false NOT NULL,
    "aspect_A5" boolean DEFAULT false NOT NULL,
    "aspect_A6" boolean DEFAULT false NOT NULL,
    "aspect_A7" boolean DEFAULT false NOT NULL,
    "crit_B" boolean DEFAULT false NOT NULL,
    "aspect_B1" boolean DEFAULT false NOT NULL,
    "aspect_B2" boolean DEFAULT false NOT NULL,
    "aspect_B3" boolean DEFAULT false NOT NULL,
    "aspect_B4" boolean DEFAULT false NOT NULL,
    "aspect_B5" boolean DEFAULT false NOT NULL,
    "aspect_B6" boolean DEFAULT false NOT NULL,
    "aspect_B7" boolean DEFAULT false NOT NULL,
    "crit_C" boolean DEFAULT false NOT NULL,
    "aspect_C1" boolean DEFAULT false NOT NULL,
    "aspect_C2" boolean DEFAULT false NOT NULL,
    "aspect_C3" boolean DEFAULT false NOT NULL,
    "aspect_C4" boolean DEFAULT false NOT NULL,
    "aspect_C5" boolean DEFAULT false NOT NULL,
    "aspect_C6" boolean DEFAULT false NOT NULL,
    "aspect_C7" boolean DEFAULT false NOT NULL,
    "crit_D" boolean DEFAULT false NOT NULL,
    "aspect_D1" boolean DEFAULT false NOT NULL,
    "aspect_D2" boolean DEFAULT false NOT NULL,
    "aspect_D3" boolean DEFAULT false NOT NULL,
    "aspect_D4" boolean DEFAULT false NOT NULL,
    "aspect_D5" boolean DEFAULT false NOT NULL,
    "aspect_D6" boolean DEFAULT false NOT NULL,
    "aspect_D7" boolean DEFAULT false NOT NULL,
    "crit_E" boolean DEFAULT false NOT NULL,
    "aspect_E1" boolean DEFAULT false NOT NULL,
    "aspect_E2" boolean DEFAULT false NOT NULL,
    "aspect_E3" boolean DEFAULT false NOT NULL,
    "aspect_E4" boolean DEFAULT false NOT NULL,
    "aspect_E5" boolean DEFAULT false NOT NULL,
    "aspect_E6" boolean DEFAULT false NOT NULL,
    "aspect_E7" boolean DEFAULT false NOT NULL,
    "crit_F" boolean DEFAULT false NOT NULL,
    aspect_f1 boolean DEFAULT false NOT NULL,
    "aspect_F2" boolean DEFAULT false NOT NULL,
    "aspect_F3" boolean DEFAULT false NOT NULL,
    "aspect_F4" boolean DEFAULT false NOT NULL,
    "aspect_F5" boolean DEFAULT false NOT NULL,
    "aspect_F6" boolean DEFAULT false NOT NULL,
    "aspect_F7" boolean DEFAULT false NOT NULL,
    fk_relconcept1 smallint DEFAULT 0,
    fk_relconcept2 smallint DEFAULT 0,
    fk_relconcept3 smallint DEFAULT 0,
    fk_relconcept4 smallint DEFAULT 0,
    id_order_in_yearsubject smallint NOT NULL,
    fk_classroom_termsubject_id integer NOT NULL,
    fk_globalcontext_id integer DEFAULT 0,
    fk_keyconcept_id integer DEFAULT 0,
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- Table: larcauth_unit_period
CREATE TABLE public.larcauth_unit_period (
    id integer NOT NULL,
    unit_nr smallint NOT NULL,
    label character varying(15) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    created timestamp with time zone NOT NULL,
    updated timestamp with time zone NOT NULL,
    fk_language_id integer NOT NULL,
    titre1_lang character varying(72),
    titre1_lang_cat1 character varying(72),
    titre1_lang_cat2 character varying(72),
    titre1_lang_cat3 character varying(72),
    titre1_lang_cat4 character varying(72),
    titre2_math character varying(72),
    titre2_math_cat1 character varying(72),
    titre2_math_cat2 character varying(72),
    titre2_math_cat3 character varying(72),
    titre2_math_cat4 character varying(72),
    titre3_expl character varying(72),
    titre3_expl_cat1 character varying(72),
    titre3_expl_cat2 character varying(72),
    titre3_expl_cat3 character varying(72),
    titre3_expl_cat4 character varying(72),
    titre4_arts character varying(72),
    titre4_arts_cat1 character varying(72),
    titre4_arts_cat2 character varying(72),
    titre4_arts_cat3 character varying(72),
    titre4_arts_cat4 character varying(72),
    titre5_phys character varying(72),
    titre5_phys_cat1 character varying(72),
    titre5_phys_cat2 character varying(72),
    titre5_phys_cat3 character varying(72),
    titre5_phys_cat4 character varying(72),
    -- Colonnes de synchronisation
    sync_version BIGINT DEFAULT 0,
    synced_at TIMESTAMPTZ,
    synced_by INTEGER
);

-- ============================================================
-- APPLICATION DES TRIGGERS SUR TOUTES LES TABLES
-- ============================================================

-- Fonction helper pour appliquer le trigger à une table
-- Note: Dans un vrai script de migration, on utiliserait un DO block ou un script externe.
-- Ici, nous listons les commandes pour chaque table manuellement pour être explicite.

CREATE TRIGGER trg_sync_larcauth_academicyear
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_academicyear
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_aecuser
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_aecuser
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_agenda
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_agenda
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_campus
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_campus
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_classroom
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_classroom
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_classroom_has_timeperiod
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_classroom_has_timeperiod
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_classroom_termothersubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_classroom_termothersubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_classroom_termsubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_classroom_termsubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_concept
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_concept
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_criteria_of_levelsubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_criteria_of_levelsubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_criteria_of_subjectsgroup
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_criteria_of_subjectsgroup
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_district
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_district
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_edt_classe
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_edt_classe
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_evaluation
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_evaluation
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_gender
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_gender
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_globalcontext
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_globalcontext
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_language
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_language
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learner_has_subjectgroup
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learner_has_subjectgroup
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learner_has_term
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learner_has_term
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learner_has_termothersubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learner_has_termothersubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learner_has_termsubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learner_has_termsubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnerdp_has_termsubjectdp
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnerdp_has_termsubjectdp
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnermat_has_devpers_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnermat_has_devpers_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnermat_has_subjectevals_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnermat_has_subjectevals_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnermat_has_unit_period
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnermat_has_unit_period
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnerpei_has_termsubjectpei
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnerpei_has_termsubjectpei
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnerpp_has_termsubjectpp
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnerpp_has_termsubjectpp
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_learnerprim_has_unit_period
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_learnerprim_has_unit_period
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_level
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_level
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_levelsubject
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_levelsubject
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_lieu
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_lieu
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_devpers_gene
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_devpers_gene
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_devpers_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_devpers_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_subjectevals_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_subjectevals_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_subjectskills
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_subjectskills
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_subjectskills_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_subjectskills_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_mat_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_mat_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_natureparentutor
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_natureparentutor
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_program
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_program
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_student
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_student
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_student_has_dayevents
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_student_has_dayevents
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_student_has_events
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_student_has_events
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_student_has_termevents
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_student_has_termevents
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_student_has_weekevents
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_student_has_weekevents
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_subjectgroup
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_subjectgroup
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_teachadm
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_teachadm
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_term
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_term
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_termsubject_has_homework
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_termsubject_has_homework
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_timeperiod
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_timeperiod
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_type_event
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_type_event
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_unit
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_unit
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

CREATE TRIGGER trg_sync_larcauth_unit_period
BEFORE INSERT OR UPDATE OR DELETE ON public.larcauth_unit_period
FOR EACH ROW EXECUTE FUNCTION public.handle_sync_update();

-- FIN DU SCRIPT
