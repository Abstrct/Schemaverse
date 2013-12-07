-- Revert function-in_range_planet

BEGIN;

DROP FUNCTION in_range_planet(integer, integer);

COMMIT;
