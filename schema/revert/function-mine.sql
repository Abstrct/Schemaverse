-- Revert function-mine

BEGIN;

DROP FUNCTION mine(integer, integer);

COMMIT;
