-- Revert function-set_char_variable

BEGIN;

DROP FUNCTION set_char_variable(character varying, character varying);

COMMIT;
