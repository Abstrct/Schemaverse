-- Revert function-get_numeric_variable

BEGIN;

DROP FUNCTION get_numeric_variable(character varying);

COMMIT;
