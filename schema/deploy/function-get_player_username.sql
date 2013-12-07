-- Deploy function-get_player_username
-- requires: table-player

BEGIN;

CREATE OR REPLACE FUNCTION get_player_username(check_player_id integer)
  RETURNS character varying AS
$BODY$
	SELECT username FROM public.player WHERE id=$1;
$BODY$
  LANGUAGE sql STABLE SECURITY DEFINER
  COST 100;

COMMIT;
