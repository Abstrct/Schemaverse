-- Deploy trigger-player_creation
-- requires: table-player

BEGIN;


CREATE OR REPLACE FUNCTION player_creation()
  RETURNS trigger AS
$BODY$
DECLARE 
	new_planet RECORD;
BEGIN
	execute 'CREATE ROLE ' || NEW.username || ' WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '''|| NEW.password ||'''  IN GROUP players'; 

	IF (SELECT count(*) FROM planets WHERE conqueror_id IS NULL) > 0 THEN
		UPDATE planet SET conqueror_id=NEW.id, mine_limit=50, fuel=3000000, difficulty=10 
			WHERE planet.id = 
				(SELECT id FROM planet WHERE conqueror_id is null ORDER BY RANDOM() LIMIT 1);
	ELSE
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
                50 as mine_limit,
                3000000 as fuel,
                10 as difficulty,
		point(
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer 
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer
		END,
                CASE (RANDOM() * 1)::integer % 2
                        WHEN 0 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR'))::integer
                        WHEN 1 THEN (RANDOM() * GET_NUMERIC_VARIABLE('UNIVERSE_CREATOR') * -1)::integer		
		END) as location
		FROM generate_series(1,10)
		LOOP
			if not exists (select 1 from planet where (location <-> new_planet.location) <= 3000) then
				INSERT INTO planet(id, name, mine_limit, difficulty, fuel, location, location_x, location_y, conqueror_id)
					VALUES(new_planet.id, new_planet.name, new_planet.mine_limit, new_planet.difficulty, new_planet.fuel, new_planet.location,new_planet.location[0],new_planet.location[1], NEW.id);
				Exit;
			END IF;	
		END LOOP;
	END IF;

	INSERT INTO player_round_stats(player_id, round_id) VALUES (NEW.id, (select last_value from round_seq));
	INSERT INTO player_overall_stats(player_id) VALUES (NEW.id);



RETURN NEW;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE TRIGGER player_creation
  AFTER INSERT
  ON player
  FOR EACH ROW
  EXECUTE PROCEDURE player_creation();


COMMIT;
