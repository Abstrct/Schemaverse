-- Verify function-fleet_fail_event

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'fleet_fail_event';

ROLLBACK;
