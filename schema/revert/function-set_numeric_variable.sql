-- Revert function-set_numeric_variable

BEGIN;

DROP FUNCTION set_numeric_variable(character varying, integer);

COMMIT;
