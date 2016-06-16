-- Revert function-get_fleet_runtime

BEGIN;

DROP FUNCTION get_fleet_runtime(integer, character varying);

COMMIT;
