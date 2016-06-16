-- Deploy view-planets
-- requires: table-planet

BEGIN;

CREATE OR REPLACE VIEW planets AS 
 SELECT planet.id, planet.name, planet.mine_limit, planet.location_x, 
    planet.location_y, planet.conqueror_id, planet.location
   FROM planet;


CREATE OR REPLACE RULE planet_update AS
    ON UPDATE TO planets DO INSTEAD  UPDATE planet SET name = new.name
  WHERE planet.id <> 1 AND planet.id = new.id AND planet.conqueror_id = get_player_id("session_user"());

COMMIT;
