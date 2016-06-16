-- Revert function-refuel_ship

BEGIN;

DROP FUNCTION refuel_ship(integer);

COMMIT;
