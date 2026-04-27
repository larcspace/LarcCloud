@echo off
setlocal EnableDelayedExpansion

:: ==========================================
:: CONFIGURATION - REMPLIS CES LIGNES
:: ==========================================
set LOCAL_HOST=localhost
set LOCAL_PORT=5432
set LOCAL_DB=xxxx
set LOCAL_USER=
set LOCAL_PASS=

:: Chemin vers psql (si non reconnu, décommente et ajuste le chemin)
:: set PSQL_CMD="C:\Program Files\PostgreSQL\16\bin\psql.exe"
set PSQL_CMD=psql

:: Dossier de sortie
set TEMP_DIR=csv_export
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo ==========================================
echo DEMARRAGE EXPORT CSV - BASE LOCALE (UTF-8)
echo ==========================================
echo Base : %LOCAL_DB%
echo Destination : %TEMP_DIR%
echo.

:: LISTE DES 52 TABLES DANS L'ORDRE DE DÉPENDANCE
set TABLE_LIST=larcauth_language larcauth_district larcauth_gender larcauth_natureparentutor larcauth_program larcauth_academicyear larcauth_term larcauth_unit_period larcauth_campus larcauth_level larcauth_subjectgroup larcauth_levelsubject larcauth_criteria_of_subjectsgroup larcauth_concept larcauth_globalcontext larcauth_lieu larcauth_timeperiod larcauth_type_event larcauth_aecuser larcauth_student larcauth_teachadm larcauth_classroom larcauth_mat_unit larcauth_mat_devpers_gene larcauth_mat_devpers_unit larcauth_mat_subjectskills larcauth_mat_subjectskills_unit larcauth_mat_subjectevals_unit larcauth_classroom_termsubject larcauth_classroom_termothersubject larcauth_classroom_has_timeperiod larcauth_edt_classe larcauth_termsubject_has_homework larcauth_unit larcauth_criteria_of_levelsubject larcauth_evaluation larcauth_learner_has_term larcauth_learner_has_subjectgroup larcauth_learner_has_termsubject larcauth_learner_has_termothersubject larcauth_learnermat_has_devpers_unit larcauth_learnermat_has_subjectevals_unit larcauth_learnermat_has_unit_period larcauth_learnerprim_has_unit_period larcauth_learnerdp_has_termsubjectdp larcauth_learnerpei_has_termsubjectpei larcauth_learnerpp_has_termsubjectpp larcauth_student_has_dayevents larcauth_student_has_events larcauth_student_has_weekevents larcauth_student_has_termevents larcauth_agenda

echo Nombre de tables a traiter...
set count=0
for %%t in (%TABLE_LIST%) do set /a count+=1
echo Total tables detectees : %count%
echo.

:: DEFINITION DU MOT DE PASSE
set PGPASSWORD=%LOCAL_PASS%

:: BOUCLE D'EXPORT
for %%t in (%TABLE_LIST%) do (
    echo [INFO] Export de la table : %%t
    
    :: Commande psql avec \copy et ENCODING 'UTF8' pour Supabase
    %PSQL_CMD% -h %LOCAL_HOST% -p %LOCAL_PORT% -U %LOCAL_USER% -d %LOCAL_DB% -c "\copy (SELECT * FROM %%t) TO '%TEMP_DIR%\%%t.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
    
    if errorlevel 1 (
        echo [ERREUR] Echec de l'export de %%t.
    ) else (
        echo [SUCCES] Fichier cree : %TEMP_DIR%\%%t.csv
    )
    echo.
)

echo ==========================================
echo EXPORT TERMINE - FICHIERS EN UTF-8
echo ==========================================
pause
