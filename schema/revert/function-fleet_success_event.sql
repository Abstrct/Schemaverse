-- Revert function-fleet_success_event

BEGIN;

DROP FUNCTION fleet_success_event(integer, interval);

COMMIT;
