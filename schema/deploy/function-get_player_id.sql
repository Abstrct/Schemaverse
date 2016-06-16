-- Deploy function-get_player_id
-- requires: table-player

BEGIN;

CREATE OR REPLACE FUNCTION GET_PLAYER_ID(check_username name) RETURNS integer AS $get_player_id$
	SELECT id FROM public.player WHERE username=$1;
$get_player_id$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMIT;
