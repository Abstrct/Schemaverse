-- Verify function-run_fleet_script

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'run_fleet_script';

ROLLBACK;
