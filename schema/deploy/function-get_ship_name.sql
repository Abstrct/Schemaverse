-- Deploy function-get_ship_name
-- requires: table-ship

BEGIN;

CREATE OR REPLACE FUNCTION get_ship_name(ship_id integer)
  RETURNS character varying AS
$BODY$
DECLARE 
	found_shipname character varying;
BEGIN
	SET search_path to public;
	SELECT name INTO found_shipname FROM ship WHERE id=ship_id;
	RETURN found_shipname;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
