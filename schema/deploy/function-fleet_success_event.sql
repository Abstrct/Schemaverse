-- Deploy function-fleet_success_event
-- requires: table-event

BEGIN;

CREATE OR REPLACE FUNCTION fleet_success_event(fleet integer, took interval)
  RETURNS boolean AS
$BODY$
BEGIN
	SET search_path to public;
	INSERT INTO event(action, player_id_1, public, tic, descriptor_string, referencing_id) 
		VALUES('FLEET_SUCCESS',GET_PLAYER_ID(SESSION_USER),'f',(SELECT last_value FROM tic_seq),took, fleet) ;
	RETURN 't';
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
