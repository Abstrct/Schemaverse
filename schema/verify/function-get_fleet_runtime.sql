-- Verify function-get_fleet_runtime

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_fleet_runtime';

ROLLBACK;
