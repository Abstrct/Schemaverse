-- Deploy function-repair
-- requires: table-ship
-- requires: function-in_range_ship

BEGIN;


CREATE OR REPLACE FUNCTION repair(repair_ship integer, repaired_ship integer)
  RETURNS integer AS
$BODY$
DECLARE
	repair_rate integer;
	repair_ship_name character varying;
	repair_ship_player_id integer;
	repaired_ship_name character varying;
	loc point;
BEGIN
	SET search_path to public;

	repair_rate = 0;


	--check range
	IF ACTION_PERMISSION_CHECK(repair_ship) AND (IN_RANGE_SHIP(repair_ship, repaired_ship)) THEN

		SELECT engineering, player_id, name, location INTO repair_rate, repair_ship_player_id, repair_ship_name, loc FROM ship WHERE id=repair_ship;
		SELECT name INTO repaired_ship_name FROM ship WHERE id=repaired_ship;
		UPDATE ship SET future_health = future_health + repair_rate WHERE id=repaired_ship;
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=repair_ship;

		INSERT INTO event(action, player_id_1,ship_id_1, ship_id_2, descriptor_numeric, location, public, tic)
			VALUES('REPAIR',repair_ship_player_id, repair_ship,  repaired_ship , repair_rate,loc,'t',(SELECT last_value FROM tic_seq));

	ELSE 
		 EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Repair from ' || repair_ship || ' to '|| repaired_ship ||' failed'';';
	END IF;	

	RETURN repair_rate;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
