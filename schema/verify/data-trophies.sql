-- Verify data-trophies

BEGIN;

SELECT 1/(CASE WHEN count(*) >= 29 THEN 1 ELSE 0 END) FROM trophy WHERE creator = 0 AND approved;
SELECT 1/(CASE WHEN count(*) >= 29 THEN 1 ELSE 0 END) FROM pg_proc WHERE proname LIKE 'trophy\_script\_%';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'trophy_script_update' AND tgenabled <> 'D';

ROLLBACK;
