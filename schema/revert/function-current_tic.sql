-- Revert function-current_tic

BEGIN;

DROP FUNCTION current_tic();

COMMIT;
