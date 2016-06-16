-- Deploy view-my_ship_flight_recorder
-- requires: table-ship_flight_recorder

BEGIN;

CREATE OR REPLACE VIEW my_ships_flight_recorder AS 
 WITH current_player AS (
         SELECT get_player_id("session_user"()) AS player_id
        )
 SELECT ship_flight_recorder.ship_id, ship_flight_recorder.tic, 
    ship_flight_recorder.location, 
    ship_flight_recorder.location[0] AS location_x, 
    ship_flight_recorder.location[1] AS location_y
   FROM ship_flight_recorder, current_player
  WHERE ship_flight_recorder.player_id = current_player.player_id;

COMMIT;
