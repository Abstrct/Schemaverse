-- Deploy function-round_control

BEGIN;


CREATE OR REPLACE FUNCTION round_control()
  RETURNS boolean AS
$BODY$
DECLARE
	new_planet record;
	trophies RECORD;
	players RECORD;
	p RECORD;
BEGIN

	IF NOT SESSION_USER = 'schemaverse' THEN
		RETURN 'f';
	END IF;	

	IF NOT GET_CHAR_VARIABLE('ROUND_START_DATE')::date <= 'today'::date - GET_CHAR_VARIABLE('ROUND_LENGTH')::interval THEN
		RETURN 'f';
	END IF;


	UPDATE round_stats SET
        	avg_damage_taken = current_round_stats.avg_damage_taken,
                avg_damage_done = current_round_stats.avg_damage_done,
                avg_planets_conquered = current_round_stats.avg_planets_conquered,
                avg_planets_lost = current_round_stats.avg_planets_lost,
                avg_ships_built = current_round_stats.avg_ships_built,
                avg_ships_lost = current_round_stats.avg_ships_lost,
                avg_ship_upgrades =current_round_stats.avg_ship_upgrades,
                avg_fuel_mined = current_round_stats.avg_fuel_mined
        FROM current_round_stats
        WHERE round_stats.round_id=(SELECT last_value FROM round_seq);

	FOR players IN SELECT * FROM player LOOP
		UPDATE player_round_stats SET 
			damage_taken = least(2147483647, current_player_stats.damage_taken),
			damage_done = least(2147483647,current_player_stats.damage_done),
			planets_conquered = least(32767,current_player_stats.planets_conquered),
			planets_lost = least(32767,current_player_stats.planets_lost),
			ships_built = least(32767,current_player_stats.ships_built),
			ships_lost = least(32767,current_player_stats.ships_lost),
			ship_upgrades =least(2147483647,current_player_stats.ship_upgrades),
			fuel_mined = current_player_stats.fuel_mined,
			last_updated=NOW()
		FROM current_player_stats
		WHERE player_round_stats.player_id=players.id AND current_player_stats.player_id=players.id AND player_round_stats.round_id=(select last_value from round_seq);

		UPDATE player_overall_stats SET 
			damage_taken = player_overall_stats.damage_taken + player_round_stats.damage_taken,
			damage_done = player_overall_stats.damage_done + player_round_stats.damage_done,
			planets_conquered = player_overall_stats.planets_conquered + player_round_stats.planets_conquered,
			planets_lost = player_overall_stats.planets_lost + player_round_stats.planets_lost,
			ships_built = player_overall_stats.ships_built +player_round_stats.ships_built,
			ships_lost = player_overall_stats.ships_lost + player_round_stats.ships_lost,
			ship_upgrades = player_overall_stats.ship_upgrades + player_round_stats.ship_upgrades,
			fuel_mined = player_overall_stats.fuel_mined + player_round_stats.fuel_mined
		FROM player_round_stats
		WHERE player_overall_stats.player_id=player_round_stats.player_id 
			and player_overall_stats.player_id=players.id and player_round_stats.round_id=(select last_value from round_seq);
	END LOOP;


	FOR trophies IN SELECT id FROM trophy WHERE approved='t' ORDER by run_order ASC LOOP
		EXECUTE 'INSERT INTO player_trophy SELECT * FROM trophy_script_' || trophies.id ||'((SELECT last_value FROM round_seq)::integer);';
	END LOOP;

	alter table planet disable trigger all;
	alter table fleet disable trigger all;
	alter table planet_miners disable trigger all;
	alter table ship_flight_recorder disable trigger all;
	alter table ship_control disable trigger all;
	alter table ship disable trigger all;
	alter table event disable trigger all;

	--Deactive all fleets
        update fleet set runtime='0 minutes', enabled='f';

	--add archives of stats and events
	CREATE TEMP TABLE tmp_current_round_archive AS SELECT (SELECT last_value FROM round_seq), event.* FROM event;
	EXECUTE 'COPY tmp_current_round_archive TO ''/hell/schemaverse_round_' || (SELECT last_value FROM round_seq) || '.csv''  WITH DELIMITER ''|''';

	--Delete everything else
        DELETE FROM planet_miners;
        DELETE FROM ship_flight_recorder;
        DELETE FROM ship_control;
        DELETE FROM ship;
        DELETE FROM event;
        delete from planet WHERE id != 1;

	UPDATE fleet SET last_script_update_tic=0;

        alter sequence event_id_seq restart with 1;
        alter sequence ship_id_seq restart with 1;
        alter sequence tic_seq restart with 1;
	alter sequence planet_id_seq restart with 2;


	--Reset player resources
        UPDATE player set balance=10000, fuel_reserve=100000 WHERE username!='schemaverse';
    	UPDATE fleet SET runtime='1 minute', enabled='t' FROM player WHERE player.starting_fleet=fleet.id AND player.id=fleet.player_id;
 

	UPDATE planet SET fuel=20000000 WHERE id=1;

	WHILE (SELECT count(*) FROM planet) < (SELECT count(*) FROM player) * 1.05 LOOP
		FOR new_planet IN SELECT
			nextval('planet_id_seq') as id,
			CASE (RANDOM() * 11)::integer % 12
			WHEN 0 THEN 'Aethra_' || generate_series
                         WHEN 1 THEN 'Mony_' || generate_series
                         WHEN 2 THEN 'Semper_' || generate_series
                         WHEN 3 THEN 'Voit_' || generate_series
                         WHEN 4 THEN 'Lester_' || generate_series 
                         WHEN 5 THEN 'Rio_' || generate_series 
                         WHEN 6 THEN 'Zergon_' || generate_series 
                         WHEN 7 THEN 'Cannibalon_' || generate_series
                         WHEN 8 THEN 'Omicron Persei_' || generate_series
                         WHEN 9 THEN 'Urectum_' || generate_series
                         WHEN 10 THEN 'Wormulon_' || generate_series
                         WHEN 11 THEN 'Kepler_' || generate_series
			END as name,
                GREATEST((RANDOM() * 100)::integer, 30) as mine_limit,
                GREATEST((RANDOM() * 1000000000)::integer, 100000000) as fuel,
                GREATEST((RANDOM() * 10)::integer,2) as difficulty,
		point(
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer 
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer
		END,
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer		
		END) as location
		FROM generate_series(1,500)
		LOOP
			if not exists (select 1 from planet where (location <-> new_planet.location) <= 3000) then
				INSERT INTO planet(id, name, mine_limit, difficulty, fuel, location, location_x, location_y)
					VALUES(new_planet.id, new_planet.name, new_planet.mine_limit, new_planet.difficulty, new_planet.fuel, new_planet.location,new_planet.location[0],new_planet.location[1]);
			END IF;	
		END LOOP;
	END LOOP;

	UPDATE planet SET conqueror_id=NULL WHERE planet.id = 1;
	FOR p IN SELECT player.id as id FROM player ORDER BY player.id LOOP
		UPDATE planet SET conqueror_id=p.id, mine_limit=30, fuel=500000000, difficulty=2 
			WHERE planet.id = (SELECT id FROM planet WHERE planet.id != 1 AND conqueror_id IS NULL ORDER BY RANDOM() LIMIT 1);
	END LOOP;

	alter table event enable trigger all;
	alter table planet enable trigger all;
	alter table fleet enable trigger all;
	alter table planet_miners enable trigger all;
	alter table ship_flight_recorder enable trigger all;
	alter table ship_control enable trigger all;
	alter table ship enable trigger all;

	PERFORM nextval('round_seq');

	UPDATE variable SET char_value='today'::date WHERE name='ROUND_START_DATE';


	FOR players IN SELECT * from player WHERE ID <> 0 LOOP
		INSERT INTO player_round_stats(player_id, round_id) VALUES (players.id, (select last_value from round_seq));
	END LOOP;
	INSERT INTO round_stats(round_id) VALUES((SELECT last_value FROM round_seq));

        RETURN 't';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMIT;
