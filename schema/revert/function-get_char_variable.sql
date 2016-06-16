-- Revert function-get_char_variable

BEGIN;

DROP FUNCTION get_char_variable(character varying);

COMMIT;
