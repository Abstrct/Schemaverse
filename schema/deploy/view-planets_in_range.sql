-- Deploy view-planets_in_range
-- requires: table-planet

BEGIN;

CREATE OR REPLACE VIEW planets_in_range AS 
 SELECT s.id AS ship, sp.id AS planet, s.location AS ship_location, 
    sp.location AS planet_location, s.location <-> sp.location AS distance
   FROM ship s, planet sp
  WHERE 
	s.player_id = get_player_id("session_user"()) 
	AND NOT s.destroyed 
	AND circle(s.location, s.range::double precision) @> circle(sp.location, 1::double precision);

COMMIT;
