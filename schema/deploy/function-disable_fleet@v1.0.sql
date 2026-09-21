-- Deploy function-disable_fleet
-- requires: table-fleet

BEGIN;


CREATE OR REPLACE FUNCTION disable_fleet(fleet_id integer)
  RETURNS boolean AS
$BODY$
DECLARE
BEGIN
	IF CURRENT_USER = 'schemaverse' THEN
		UPDATE fleet SET enabled='f' WHERE id=fleet_id;
	ELSE 
		UPDATE fleet SET enabled='f' WHERE id=fleet_id  AND player_id=GET_PLAYER_ID(SESSION_USER);
	END IF;
	RETURN 't'; 
END $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
