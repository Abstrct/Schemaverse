-- Deploy function-action_permission_check

BEGIN;


CREATE OR REPLACE FUNCTION action_permission_check(ship_id integer)
  RETURNS boolean AS
$BODY$
DECLARE 
	ships_player_id integer;
	lat integer;
	exploded boolean;
	ch integer;
BEGIN
	SET search_path to public;
	SELECT player_id, last_action_tic, destroyed, current_health into ships_player_id, lat, exploded, ch FROM ship WHERE id=ship_id ;
	IF (
		lat != (SELECT last_value FROM tic_seq)
		AND
		exploded = 'f'
		AND 
		ch > 0 
	) AND (
		ships_player_id = GET_PLAYER_ID(SESSION_USER) 
			OR (ships_player_id > 0 AND (SESSION_USER = 'schemaverse' OR CURRENT_USER = 'schemaverse'))  
			)
			THEN
		
		RETURN 't';
	ELSE 
		RETURN 'f';
	END IF;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
