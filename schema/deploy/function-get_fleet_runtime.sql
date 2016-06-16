-- Deploy function-get_fleet_runtime
-- requires: table-fleet

BEGIN;


CREATE OR REPLACE FUNCTION get_fleet_runtime(fleet_id integer, username character varying)
  RETURNS interval AS
$BODY$
DECLARE
	fleet_runtime interval;
BEGIN
	SET search_path to public;
	SELECT runtime INTO fleet_runtime FROM fleet WHERE id=fleet_id AND (GET_PLAYER_ID(username)=player_id);
	RETURN fleet_runtime;
END 
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
