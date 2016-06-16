-- Revert function-get_planet_name

BEGIN;

DROP FUNCTION get_planet_name(integer);

COMMIT;
