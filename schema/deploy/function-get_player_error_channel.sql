-- Deploy function-get_player_error_channel
-- requires: table-player

BEGIN;

CREATE OR REPLACE FUNCTION get_player_error_channel(player_name character varying DEFAULT SESSION_USER)
  RETURNS character varying AS
$BODY$
DECLARE 
	found_error_channel character varying;
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		SELECT error_channel INTO found_error_channel FROM player WHERE username=player_name;
        ELSE
		SELECT error_channel INTO found_error_channel FROM my_player LIMIT 1;
	END IF;
	RETURN found_error_channel;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
