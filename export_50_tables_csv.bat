@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: SCRIPT D'EXPORT DES 50 TABLES LARC EN CSV
:: ============================================================
:: Ce script exporte chaque table de votre base locale PostgreSQL
:: vers un fichier CSV dans le dossier "csv_export".
:: ============================================================

:: --- CONFIGURATION À REMPLIR ---
set LOCAL_HOST=localhost
set LOCAL_PORT=5432
set LOCAL_DB=NOM_DE_TA_BASE_LOCALE
set LOCAL_USER=postgres
set LOCAL_PASS=TON_MOT_DE_PASSE_LOCAL

:: Dossier de sortie
set OUTPUT_DIR=csv_export
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

echo.
echo ==========================================
echo EXPORT DES DONNEES LARC VERS CSV
echo ==========================================
echo Destination: %CD%\%OUTPUT_DIR%
echo.

:: Liste des 50 tables DANS L'ORDRE DE DÉPENDANCE (Parents -> Enfants)
:: Modifie cette liste si nécessaire
set TABLES=larcauth_language larcauth_district larcauth_gender larcauth_program larcauth_academicyear larcauth_campus larcauth_term larcauth_unit_period larcauth_level larcauth_subjectgroup larcauth_levelsubject larcauth_concept larcauth_globalcontext larcauth_criteria_of_subjectsgroup larcauth_criteria_of_levelsubject larcauth_mat_devpers_gene larcauth_mat_subjectskills larcauth_timeperiod larcauth_type_event larcauth_natureparentutor larcauth_lieu larcauth_aecuser larcauth_student larcauth_teachadm larcauth_classroom larcauth_classroom_termsubject larcauth_classroom_termothersubject larcauth_classroom_has_timeperiod larcauth_edt_classe larcauth_mat_unit larcauth_unit larcauth_mat_devpers_unit larcauth_mat_subjectevals_unit larcauth_learner_has_subjectgroup larcauth_learner_has_term larcauth_learner_has_termsubject larcauth_learner_has_termothersubject larcauth_learnermat_has_devpers_unit larcauth_learnermat_has_subjectevals_unit larcauth_learnermat_has_unit_period larcauth_learnerprim_has_unit_period larcauth_learnerdp_has_termsubjectdp larcauth_learnerpei_has_termsubjectpei larcauth_learnerpp_has_termsubjectpp larcauth_evaluation larcauth_termsubject_has_homework larcauth_student_has_dayevents larcauth_student_has_events larcauth_student_has_termevents larcauth_student_has_weekevents larcauth_agenda

echo.
echo Démarrage de l'export...
echo.

set COUNT=0
set ERROR_COUNT=0

for %%t in (%TABLES%) do (
    set /a COUNT+=1
    echo [!COUNT!] Export de la table : %%t
    
    :: Commande psql avec \copy pour exporter en CSV
    :: On utilise une requête SQL directe pour gérer le format CSV proprement
    psql -h %LOCAL_HOST% -p %LOCAL_PORT% -U %LOCAL_USER% -d %LOCAL_DB% -c "\copy %%t to '%OUTPUT_DIR%\%%t.csv' with (format csv, header true, encoding 'UTF8');"
    
    if errorlevel 1 (
        echo   [ERREUR] Echec de l'export de %%t. Vérifiez si la table existe ou est vide.
        set /a ERROR_COUNT+=1
    ) else (
        echo   [OK] Fichier cree: %OUTPUT_DIR%\%%t.csv
    )
)

echo.
echo ==========================================
echo EXPORT TERMINE
echo ==========================================
echo Tables traitees: %COUNT%
echo Erreurs: %ERROR_COUNT%
echo.
echo Les fichiers CSV sont dans le dossier: %CD%\%OUTPUT_DIR%
echo.
pause
