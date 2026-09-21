-- Revert function-current_round

BEGIN;

DROP FUNCTION current_round();

COMMIT;
