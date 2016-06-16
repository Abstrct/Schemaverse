-- Revert function-in_range_ship

BEGIN;

DROP FUNCTION in_range_ship(integer, integer);

COMMIT;
