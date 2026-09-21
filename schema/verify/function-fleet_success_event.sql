-- Verify function-fleet_success_event

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'fleet_success_event';

ROLLBACK;
