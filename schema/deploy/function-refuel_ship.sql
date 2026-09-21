-- Deploy function-refuel_ship
-- requires: function-refuel_ship@v1.0
--
-- Rework: only the owner of a living ship can refuel it.

BEGIN;

CREATE OR REPLACE FUNCTION refuel_ship(ship_id integer)
  RETURNS integer AS
$BODY$
DECLARE
	current_fuel_reserve bigint;
	new_fuel_reserve bigint;
	current_ship_fuel bigint;
	new_ship_fuel bigint;
	max_ship_fuel bigint;
BEGIN
	SELECT current_fuel, max_fuel INTO current_ship_fuel, max_ship_fuel
	  FROM ship WHERE id=ship_id AND player_id=GET_PLAYER_ID(SESSION_USER) AND NOT destroyed;
	IF NOT FOUND THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Refuel of ship ' || ship_id || ' failed: not your ship, or it is destroyed'';';
		RETURN 0;
	END IF;

	SELECT fuel_reserve INTO current_fuel_reserve FROM player WHERE username=SESSION_USER;

	new_fuel_reserve = current_fuel_reserve - (max_ship_fuel - current_ship_fuel);
	IF new_fuel_reserve < 0 THEN
		new_ship_fuel = max_ship_fuel - (@new_fuel_reserve);
		new_fuel_reserve = 0;
	ELSE
		new_ship_fuel = max_ship_fuel;
	END IF;

	UPDATE ship SET current_fuel=new_ship_fuel WHERE id=ship_id;
	UPDATE player SET fuel_reserve=new_fuel_reserve WHERE username=SESSION_USER;

	INSERT INTO event(action, player_id_1, ship_id_1, descriptor_numeric, public, tic)
		VALUES('REFUEL_SHIP',GET_PLAYER_ID(SESSION_USER), ship_id , new_ship_fuel, 'f',(SELECT last_value FROM tic_seq));

	RETURN new_ship_fuel;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp
  COST 100;

COMMIT;
