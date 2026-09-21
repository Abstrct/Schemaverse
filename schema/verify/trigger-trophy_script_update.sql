-- Verify trigger-trophy_script_update

BEGIN;

SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'trophy_script_update' AND tgrelid = 'trophy'::regclass;
SELECT 1/(CASE WHEN prosrc ~ 'gen_random_uuid' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'trophy_script_update';

ROLLBACK;
