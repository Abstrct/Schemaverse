-- Deploy function-fleet_fail_event
-- requires: table-event

BEGIN;

CREATE OR REPLACE FUNCTION fleet_fail_event(fleet integer, error text)
  RETURNS boolean AS
$BODY$
BEGIN
	SET search_path to public;
	INSERT INTO event(action, player_id_1, public, tic, descriptor_string, referencing_id) 
		VALUES('FLEET_FAIL',GET_PLAYER_ID(SESSION_USER),'f',(SELECT last_value FROM tic_seq),error, fleet) ;
	RETURN 't';
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
