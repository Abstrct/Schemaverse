-- Deploy function-in_range_planet
-- requires: table-ship
-- requires: table-planet

BEGIN;

CREATE OR REPLACE FUNCTION in_range_planet(ship_id integer, planet_id integer)
  RETURNS boolean AS
$BODY$
	SET search_path to public;
	select exists (select 1 from planet p, ship s
	       	       where 
		       	  s.id = $1 and p.id = $2 and
                          not s.destroyed and
                          CIRCLE(s.location, s.range) @> CIRCLE(p.location, 1));
$BODY$
  LANGUAGE sql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
