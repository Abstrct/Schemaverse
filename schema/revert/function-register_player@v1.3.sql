-- Revert function-register_player

BEGIN;

DROP FUNCTION IF EXISTS register_player(text, text);
DROP ROLE IF EXISTS registrar;

COMMIT;
