-- Deploy function-mine
-- requires: table-ship
-- requires: table-planet
-- requires: function-in_range_planet

BEGIN;


CREATE OR REPLACE FUNCTION mine(ship_id integer, planet_id integer)
  RETURNS boolean AS
$BODY$
BEGIN
	SET search_path to public;
	IF ACTION_PERMISSION_CHECK(ship_id) AND (IN_RANGE_PLANET(ship_id, planet_id)) THEN
		INSERT INTO planet_miners VALUES(planet_id, ship_id);
		UPDATE ship SET last_action_tic=(SELECT last_value FROM tic_seq) WHERE id=ship_id;
		RETURN 't';
	ELSE
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Mining ' || planet_id || ' with ship '|| ship_id ||' failed'';';
		RETURN 'f';
	END IF;

END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
