-- Deploy function-in_range_ship
-- requires: table-ship

BEGIN;

CREATE OR REPLACE FUNCTION in_range_ship(ship_1 integer, ship_2 integer)
  RETURNS boolean AS
$BODY$
	SET search_path to public;
	select exists (select 1 from ship enemies, ship players
	       	       where 
		       	  players.id = $1 and enemies.id = $2 and
                          not enemies.destroyed AND NOT players.destroyed and
                          CIRCLE(players.location, players.range) @> CIRCLE(enemies.location, 1));
$BODY$
  LANGUAGE sql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
