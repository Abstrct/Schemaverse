-- Revert function-get_player_error_channel

BEGIN;

DROP FUNCTION get_player_error_channel(character varying);

COMMIT;
