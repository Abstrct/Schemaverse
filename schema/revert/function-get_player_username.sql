-- Revert function-get_player_username

BEGIN;

DROP FUNCTION get_player_username(integer);

COMMIT;
