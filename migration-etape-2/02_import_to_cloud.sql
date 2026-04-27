-- ============================================================
-- FICHIER D'IMPORT POUR SUPABASE CLOUD
-- Contient les commandes \copy pour les 52 tables
-- À exécuter avec : psql -h ... -f import_all.sql
-- ============================================================

\copy larcauth_language FROM 'csv_export/larcauth_language.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_district FROM 'csv_export/larcauth_district.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_gender FROM 'csv_export/larcauth_gender.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_natureparentutor FROM 'csv_export/larcauth_natureparentutor.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_program FROM 'csv_export/larcauth_program.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_academicyear FROM 'csv_export/larcauth_academicyear.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_term FROM 'csv_export/larcauth_term.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_unit_period FROM 'csv_export/larcauth_unit_period.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_campus FROM 'csv_export/larcauth_campus.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_level FROM 'csv_export/larcauth_level.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_subjectgroup FROM 'csv_export/larcauth_subjectgroup.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_levelsubject FROM 'csv_export/larcauth_levelsubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_criteria_of_subjectsgroup FROM 'csv_export/larcauth_criteria_of_subjectsgroup.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_concept FROM 'csv_export/larcauth_concept.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_globalcontext FROM 'csv_export/larcauth_globalcontext.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_lieu FROM 'csv_export/larcauth_lieu.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_timeperiod FROM 'csv_export/larcauth_timeperiod.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_type_event FROM 'csv_export/larcauth_type_event.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_aecuser FROM 'csv_export/larcauth_aecuser.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_student FROM 'csv_export/larcauth_student.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_teachadm FROM 'csv_export/larcauth_teachadm.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_classroom FROM 'csv_export/larcauth_classroom.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_unit FROM 'csv_export/larcauth_mat_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_devpers_gene FROM 'csv_export/larcauth_mat_devpers_gene.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_devpers_unit FROM 'csv_export/larcauth_mat_devpers_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_subjectskills FROM 'csv_export/larcauth_mat_subjectskills.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_subjectskills_unit FROM 'csv_export/larcauth_mat_subjectskills_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_mat_subjectevals_unit FROM 'csv_export/larcauth_mat_subjectevals_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_classroom_termsubject FROM 'csv_export/larcauth_classroom_termsubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_classroom_termothersubject FROM 'csv_export/larcauth_classroom_termothersubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_classroom_has_timeperiod FROM 'csv_export/larcauth_classroom_has_timeperiod.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_edt_classe FROM 'csv_export/larcauth_edt_classe.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_termsubject_has_homework FROM 'csv_export/larcauth_termsubject_has_homework.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_unit FROM 'csv_export/larcauth_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_criteria_of_levelsubject FROM 'csv_export/larcauth_criteria_of_levelsubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_evaluation FROM 'csv_export/larcauth_evaluation.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learner_has_term FROM 'csv_export/larcauth_learner_has_term.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learner_has_subjectgroup FROM 'csv_export/larcauth_learner_has_subjectgroup.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learner_has_termsubject FROM 'csv_export/larcauth_learner_has_termsubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learner_has_termothersubject FROM 'csv_export/larcauth_learner_has_termothersubject.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnermat_has_devpers_unit FROM 'csv_export/larcauth_learnermat_has_devpers_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnermat_has_subjectevals_unit FROM 'csv_export/larcauth_learnermat_has_subjectevals_unit.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnermat_has_unit_period FROM 'csv_export/larcauth_learnermat_has_unit_period.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnerprim_has_unit_period FROM 'csv_export/larcauth_learnerprim_has_unit_period.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnerdp_has_termsubjectdp FROM 'csv_export/larcauth_learnerdp_has_termsubjectdp.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnerpei_has_termsubjectpei FROM 'csv_export/larcauth_learnerpei_has_termsubjectpei.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_learnerpp_has_termsubjectpp FROM 'csv_export/larcauth_learnerpp_has_termsubjectpp.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_student_has_dayevents FROM 'csv_export/larcauth_student_has_dayevents.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_student_has_events FROM 'csv_export/larcauth_student_has_events.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_student_has_weekevents FROM 'csv_export/larcauth_student_has_weekevents.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_student_has_termevents FROM 'csv_export/larcauth_student_has_termevents.csv' WITH (FORMAT csv, HEADER true);
\copy larcauth_agenda FROM 'csv_export/larcauth_agenda.csv' WITH (FORMAT csv, HEADER true);
