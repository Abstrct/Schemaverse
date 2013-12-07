-- Deploy view-my_ships
-- requires: table-ship
-- requires: table-ship_control

BEGIN;


CREATE OR REPLACE VIEW my_ships AS 
 SELECT ship.id, ship.fleet_id, ship.player_id, ship.name, ship.last_action_tic, 
    ship.last_move_tic, ship.last_living_tic, ship.current_health, 
    ship.max_health, ship.current_fuel, ship.max_fuel, ship.max_speed, 
    ship.range, ship.attack, ship.defense, ship.engineering, ship.prospecting, 
    ship.location_x, ship.location_y, ship_control.direction, 
    ship_control.speed, ship_control.destination_x, ship_control.destination_y, 
    ship_control.repair_priority, ship_control.action, 
    ship_control.action_target_id, ship.location, ship_control.destination, 
    ship_control.target_speed, ship_control.target_direction
   FROM ship, ship_control
  WHERE ship.player_id = get_player_id("session_user"()) AND ship.id = ship_control.ship_id AND ship.destroyed = false;


CREATE OR REPLACE RULE ship_control_update AS
    ON UPDATE TO my_ships DO INSTEAD ( UPDATE ship_control SET target_speed = new.target_speed, target_direction = new.target_direction, destination_x = COALESCE(new.destination_x::double precision, new.destination[0]), 
destination_y = COALESCE(new.destination_y::double precision, new.destination[1]), destination = COALESCE(new.destination, point(new.destination_x::double precision, new.destination_y::double precision)), repair_priority = 
new.repair_priority, action = new.action, action_target_id = new.action_target_id
  WHERE ship_control.ship_id = new.id;
 UPDATE ship SET name = new.name, fleet_id = new.fleet_id
  WHERE ship.id = new.id;
);


CREATE OR REPLACE RULE ship_delete AS
    ON DELETE TO my_ships DO INSTEAD  UPDATE ship SET destroyed = true
  WHERE ship.id = old.id AND ship.player_id = get_player_id("session_user"());


CREATE OR REPLACE RULE ship_insert AS
    ON INSERT TO my_ships DO INSTEAD  INSERT INTO ship (name, range, attack, defense, engineering, prospecting, location_x, location_y, location, last_living_tic, fleet_id) 
  VALUES (new.name, COALESCE(new.range, 300), COALESCE(new.attack, 5), COALESCE(new.defense, 5), COALESCE(new.engineering, 5), COALESCE(new.prospecting, 5), COALESCE(new.location_x::double precision, new.location[0]), 
COALESCE(new.location_y::double precision, new.location[1]), COALESCE(new.location, point(new.location_x::double precision, new.location_y::double precision)), (( SELECT tic_seq.last_value
           FROM tic_seq)), COALESCE(new.fleet_id, NULL::integer))
  RETURNING ship.id, ship.fleet_id, ship.player_id, ship.name, 
    ship.last_action_tic, ship.last_move_tic, ship.last_living_tic, 
    ship.current_health, ship.max_health, ship.current_fuel, ship.max_fuel, 
    ship.max_speed, ship.range, ship.attack, ship.defense, ship.engineering, 
    ship.prospecting, ship.location_x, ship.location_y, 0, 0, 0, 0, 0, 
    ''::character(30) AS bpchar, 0, ship.location, ship.location, 0, 0;

COMMIT;
