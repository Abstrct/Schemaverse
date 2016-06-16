-- Revert function-perform-mining

BEGIN;

DROP FUNCTION perform_mining();

COMMIT;
