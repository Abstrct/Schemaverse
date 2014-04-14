-- Deploy function-move_ships
-- requires: table-ship

BEGIN;


CREATE OR REPLACE FUNCTION move_ships()
  RETURNS boolean AS
$BODY$
DECLARE
	
	ship_control_ record;
	velocity point;
	new_velocity point;
	vector point;
	delta_v numeric;
	acceleration_angle numeric;
	distance bigint;
	current_tic integer;
BEGIN
	SET search_path to public;
        IF NOT SESSION_USER = 'schemaverse' THEN
                RETURN 'f';
        END IF;

	SELECT last_value INTO current_tic FROM tic_seq;
	
	FOR ship_control_ IN SELECT SC.*, S.* FROM ship_control SC
          INNER JOIN ship S ON S.id = SC.ship_id
	  WHERE (SC.target_speed <> SC.speed
	  OR SC.target_direction <> SC.direction
	  OR SC.speed <> 0) AND SC.destination<->S.location > 1 
          AND S.destroyed='f' AND S.last_move_tic <> current_tic LOOP

	
	  -- If ship is being controlled by a set destination, adjust angle and speed appropriately
	  IF ship_control_.destination IS NOT NULL THEN
            distance :=  (ship_control_.destination <-> ship_control_.location)::bigint;
	    IF distance < ship_control_.target_speed OR ship_control_.target_speed IS NULL THEN
	      ship_control_.target_speed = distance::int;
            END IF;
	    vector := ship_control_.destination - ship_control_.location;
	    ship_control_.target_direction := DEGREES(ATAN2(vector[1], vector[0]))::int;
	    IF ship_control_.target_direction < 0 THEN
	      ship_control_.target_direction := ship_control_.target_direction + 360;
	    END IF;
	  END IF;

	  velocity := point(COS(RADIANS(ship_control_.direction)) * ship_control_.speed,
	                    SIN(RADIANS(ship_control_.direction)) * ship_control_.speed);

	  new_velocity := point(COS(RADIANS(coalesce(ship_control_.target_direction,0))) * ship_control_.target_speed,
	  	       	        SIN(RADIANS(coalesce(ship_control_.target_direction,0))) * ship_control_.target_speed);

	  vector := new_velocity - velocity;
	  delta_v := velocity <-> new_velocity;
	  acceleration_angle := ATAN2(vector[1], vector[0]);

          IF ship_control_.current_fuel < delta_v THEN
	    delta_v := ship_control_.current_fuel;
	  END IF;

	  new_velocity := velocity + point(COS(acceleration_angle)*delta_v, SIN(acceleration_angle)*delta_v);
	  ship_control_.direction = DEGREES(ATAN2(new_velocity[1], new_velocity[0]))::int;
	  IF ship_control_.direction < 0 THEN
	    ship_control_.direction := ship_control_.direction + 360;
	  END IF;
	  ship_control_.speed =  (new_velocity <-> point(0,0))::integer;
	  ship_control_.current_fuel := ship_control_.current_fuel - delta_v::int;

          -- Move the ship!
         UPDATE ship S SET
		last_move_tic = current_tic,
		current_fuel = ship_control_.current_fuel,
		location = ship_control_.location + point(COS(RADIANS(ship_control_.direction)) * ship_control_.speed,
		                                 SIN(RADIANS(ship_control_.direction)) * ship_control_.speed)
                WHERE S.id = ship_control_.id;

          UPDATE ship S SET
		location_x = location[0],
		location_y = location[1]
                WHERE S.id = ship_control_.id;
          
	  UPDATE ship_control SC SET 
		speed = ship_control_.speed,
		direction = ship_control_.direction
                WHERE SC.ship_id = ship_control_.id;
	
	END LOOP;

	RETURN 't';
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
