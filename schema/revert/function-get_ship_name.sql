-- Revert function-get_ship_name

BEGIN;

DROP FUNCTION get_ship_name(integer);

COMMIT;
