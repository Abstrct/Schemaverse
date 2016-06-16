-- Revert function-generate_string

BEGIN;

DROP FUNCTION generate_string(integer);

COMMIT;
