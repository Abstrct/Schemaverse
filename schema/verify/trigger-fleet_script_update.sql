-- Verify trigger-fleet_script_update

BEGIN;

SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'fleet_script_update' AND tgrelid = 'fleet'::regclass;
SELECT 1/(CASE WHEN prosrc ~ 'gen_random_uuid' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'fleet_script_update';

ROLLBACK;
