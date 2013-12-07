-- Deploy function-perform-mining
-- requires: function-mine

BEGIN;


CREATE OR REPLACE FUNCTION perform_mining()
  RETURNS integer AS
$BODY$
DECLARE
	miners RECORD;
	current_planet_id integer;
	current_planet_limit integer;
	current_planet_difficulty integer;
	current_planet_fuel integer;
	limit_counter integer;
	mined_player_fuel integer;
	mine_base_fuel integer;

	new_fuel_reserve bigint;
	current_tic integer;
BEGIN
	SET search_path to public;
	current_planet_id = 0; 
	mine_base_fuel = GET_NUMERIC_VARIABLE('MINE_BASE_FUEL');
	
	CREATE TEMPORARY TABLE temp_mined_player (
		player_id integer,
		planet_id integer,
		fuel_mined bigint
	);

	CREATE TEMPORARY TABLE temp_event (
		action CHARACTER(30), 
		player_id_1 integer,
		ship_id_1 integer, 
		referencing_id integer, 
		descriptor_numeric integer,
		location POINT, 
		public boolean
	);

	FOR miners IN 
		SELECT 
			planet_miners.planet_id as planet_id, 
			planet_miners.ship_id as ship_id, 
			ship.player_id as player_id, 
			ship.prospecting as prospecting,
			ship.location as location
			FROM 
				planet_miners, ship
			WHERE
				planet_miners.ship_id=ship.id
			ORDER BY planet_miners.planet_id, (ship.prospecting * RANDOM()) LOOP 

		IF current_planet_id != miners.planet_id THEN
			limit_counter := 0;
			current_planet_id := miners.planet_id;
			SELECT INTO current_planet_fuel, current_planet_difficulty, current_planet_limit fuel, difficulty, mine_limit FROM planet WHERE id=current_planet_id;
		END IF;

		--Added current_planet_fuel check here to fix negative fuel_reserve
		IF limit_counter < current_planet_limit AND current_planet_fuel > 0 THEN
			mined_player_fuel := (mine_base_fuel * RANDOM() * miners.prospecting * current_planet_difficulty)::integer;
			IF mined_player_fuel > current_planet_fuel THEN 
				mined_player_fuel = current_planet_fuel;
			END IF;

			IF mined_player_fuel <= 0 THEN
				INSERT INTO temp_event(action, player_id_1,ship_id_1, referencing_id, location, public)
					VALUES('MINE_FAIL',miners.player_id, miners.ship_id, miners.planet_id, miners.location,'f');		
			ELSE 


				current_planet_fuel := current_planet_fuel - mined_player_fuel;

				UPDATE temp_mined_player SET fuel_mined=fuel_mined + mined_player_fuel WHERE player_id=miners.player_id and planet_id=current_planet_id;
				IF NOT FOUND THEN
					INSERT INTO temp_mined_player VALUES (miners.player_id, current_planet_id, mined_player_fuel);
				END IF;

				INSERT INTO temp_event(action, player_id_1,ship_id_1, referencing_id, descriptor_numeric, location, public)
					VALUES('MINE_SUCCESS',miners.player_id, miners.ship_id, miners.planet_id , mined_player_fuel,miners.location,'f');
			END IF;
			limit_counter = limit_counter + 1;
		ELSE
			--INSERT INTO event(action, player_id_1,ship_id_1, referencing_id, location, public, tic)
			--	VALUES('MINE_FAIL',miners.player_id, miners.ship_id, miners.planet_id, miners.location,'f',(SELECT last_value FROM tic_seq));
		END IF;		
	END LOOP;

	DELETE FROM planet_miners;

	WITH tmp AS (SELECT player_id, SUM(fuel_mined) as fuel_mined FROM temp_mined_player GROUP BY player_id)
		UPDATE player SET fuel_reserve = fuel_reserve + tmp.fuel_mined FROM tmp WHERE player.id = tmp.player_id;

	WITH tmp AS (SELECT planet_id, SUM(fuel_mined) as fuel_mined FROM temp_mined_player GROUP BY planet_id)
		UPDATE planet SET fuel = GREATEST(fuel - tmp.fuel_mined,0) FROM tmp WHERE planet.id = tmp.planet_id;

	INSERT INTO event(action, player_id_1,ship_id_1, referencing_id, descriptor_numeric, location, public, tic) SELECT temp_event.*, (SELECT last_value FROM tic_seq) FROM temp_event;

	current_planet_id = 0; 

	FOR miners IN SELECT count(event.player_id_1) as mined, event.referencing_id as planet_id, event.player_id_1 as player_id, 
			CASE WHEN (select conqueror_id from planet where id=event.referencing_id)=event.player_id_1 THEN 2 ELSE 1 END as current_conqueror
			FROM temp_event event
			WHERE event.action='MINE_SUCCESS'
			GROUP BY event.referencing_id, event.player_id_1
			ORDER BY planet_id, mined DESC, current_conqueror DESC LOOP

		IF current_planet_id != miners.planet_id THEN
			current_planet_id := miners.planet_id;
			IF miners.current_conqueror=1 THEN
				UPDATE 	planet 	SET conqueror_id=miners.player_id WHERE planet.id=miners.planet_id;
			END IF;
		END IF;
	END LOOP;

	RETURN 1;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
