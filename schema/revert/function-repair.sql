-- Revert function-repair

BEGIN;

DROP FUNCTION repair(integer, integer);

COMMIT;
