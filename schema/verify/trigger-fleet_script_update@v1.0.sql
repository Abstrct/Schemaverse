-- Verify trigger-fleet_script_update@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'fleet_script_update';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'fleet_script_update';

ROLLBACK;
