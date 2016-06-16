-- Revert function-get_player_id

BEGIN;

DROP FUNCTION GET_PLAYER_ID(name);

COMMIT;
