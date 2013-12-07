-- Revert function-fleet_fail_event

BEGIN;

DROP FUNCTION fleet_fail_event(integer, text);

COMMIT;
