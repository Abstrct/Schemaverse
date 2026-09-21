-- Deploy function-player_badge
-- requires: table-player
--
-- The bits of another player that are public: name, symbol and colour. Row
-- level security hides the rest of the player table from everyone but its
-- owner, so this is a SECURITY DEFINER lookup that maps and event feeds can
-- use to label a conqueror or an attacker.

BEGIN;

CREATE OR REPLACE FUNCTION player_badge(p_id integer) RETURNS jsonb AS
$$
	SELECT jsonb_build_object('id', id, 'username', username, 'symbol', symbol, 'rgb', rgb)
	  FROM public.player WHERE id = p_id
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

COMMIT;
