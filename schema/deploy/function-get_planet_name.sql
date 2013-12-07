-- Deploy function-get_planet_name
-- requires: table-planet

BEGIN;

CREATE OR REPLACE FUNCTION get_planet_name(planet_id integer)
  RETURNS character varying AS
$BODY$
DECLARE 
	found_planetname character varying;
BEGIN
	
	SELECT name INTO found_planetname FROM public.planet WHERE id=planet_id;
	RETURN found_planetname;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
