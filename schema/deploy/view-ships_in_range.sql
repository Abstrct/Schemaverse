-- Deploy view-ships_in_range
-- requires: table-ship

BEGIN;

CREATE OR REPLACE VIEW ships_in_range AS 
 SELECT enemies.id, players.id AS ship_in_range_of, enemies.player_id, 
    enemies.name, 
    enemies.current_health::numeric / enemies.max_health::numeric AS health, 
    enemies.location AS enemy_location
   FROM ship enemies, ship players
  WHERE players.player_id = get_player_id("session_user"()) AND enemies.player_id <> players.player_id AND NOT enemies.destroyed AND NOT players.destroyed 
 AND circle(players.location, players.range::double precision) @> circle(enemies.location, 1::double precision);


COMMIT;
