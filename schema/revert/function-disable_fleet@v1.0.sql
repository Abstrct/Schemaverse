-- Revert function-disable_fleet

BEGIN;

DROP FUNCTION disable_fleet(integer);

COMMIT;
