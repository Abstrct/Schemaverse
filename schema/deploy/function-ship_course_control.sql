-- Deploy function-ship_course_control
-- requires: table-ship

BEGIN;


CREATE OR REPLACE FUNCTION ship_course_control(moving_ship_id integer, new_speed integer, new_direction integer, new_destination point)
  RETURNS boolean AS
$BODY$
DECLARE
	max_speed integer;
	ship_player_id integer;
BEGIN
	SET search_path to public;
	-- Bunch of cases where this function fails, quietly
	IF moving_ship_id IS NULL then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control on NULL ship'';';
		RETURN 'f';
	END IF;
	if new_speed IS NULL then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control NULL speed'';';
		RETURN 'f';
	END IF;
	if (new_direction IS NOT NULL AND new_destination IS NOT NULL) then
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control with both direction and destination'';';
		RETURN 'f';
	END IF;
	IF (new_direction IS NULL AND new_destination IS NULL) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Attempt to course control with neither direction nor destination'';';
		RETURN 'f';
	END IF;

	SELECT INTO max_speed, ship_player_id  ship.max_speed, player_id from ship WHERE id=moving_ship_id;
	IF ship_player_id IS NULL OR ship_player_id <> GET_PLAYER_ID(SESSION_USER) THEN
		RETURN 'f';
	END IF;
	IF new_speed > max_speed THEN
		new_speed := max_speed;
	END IF;
	UPDATE ship_control SET
	  target_speed = new_speed,
	  target_direction = new_direction,
	  destination = new_destination,
	  destination_x = new_destination[0],
	  destination_y = new_destination[1]
	  WHERE ship_id = moving_ship_id;

	RETURN 't';
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;



CREATE OR REPLACE FUNCTION ship_course_control(moving_ship_id integer, new_speed integer, new_direction integer, new_destination_x integer, new_destination_y integer)
  RETURNS boolean AS
$BODY$
DECLARE
	max_speed integer;
	ship_player_id integer;
BEGIN
	SET search_path to public;
	
	RETURN SHIP_COURSE_CONTROL(moving_ship_id, new_speed, new_direction, POINT(new_destination_x, new_destination_y));
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE OR REPLACE FUNCTION scc(moving_ship_id integer, new_speed integer, new_direction integer, new_destination_x integer, new_destination_y integer)
  RETURNS boolean AS
$BODY$
DECLARE
BEGIN
	SET search_path to public;
	RETURN ship_course_control(moving_ship_id , new_speed , new_direction , new_destination_x , new_destination_y );
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


COMMIT;
