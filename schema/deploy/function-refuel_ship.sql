-- Deploy function-refuel_ship
-- requires: table-ship

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
	SET search_path to public;

	SELECT fuel_reserve INTO current_fuel_reserve FROM player WHERE username=SESSION_USER;
	SELECT current_fuel, max_fuel INTO current_ship_fuel, max_ship_fuel FROM ship WHERE id=ship_id;

	
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
  COST 100;

COMMIT;
