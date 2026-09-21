-- Deploy trigger-player_creation
-- requires: trigger-player_creation@v1.3
-- requires: data-gameplay_variables
--
-- Rework: the SPAWN_MIN_DISTANCE lever, and the stats inserts tolerate
-- re-registration edge cases.

BEGIN;

CREATE OR REPLACE FUNCTION player_creation()
  RETURNS trigger AS
$BODY$
DECLARE
	new_planet RECORD;
	spawn_min numeric := GET_NUMERIC_VARIABLE('SPAWN_MIN_DISTANCE');
	median_ships numeric;
	home integer;
BEGIN
	-- Role creation lives in register_player(). This trigger hands out a home
	-- planet and the stats rows.

	-- Players with more living ships than the median are "established"; a new
	-- home planet keeps SPAWN_MIN_DISTANCE from their planets when it can.
	SELECT COALESCE(percentile_cont(0.5) WITHIN GROUP (ORDER BY n), 0) INTO median_ships
	  FROM (SELECT count(*)::numeric AS n FROM ship WHERE NOT destroyed AND player_id > 0 GROUP BY player_id) t;

	IF (SELECT count(*) FROM planet WHERE conqueror_id IS NULL) > 0 THEN
		SELECT id INTO home FROM planet p
		 WHERE p.conqueror_id IS NULL
		   AND (spawn_min <= 0 OR NOT EXISTS (
		         SELECT 1 FROM planet b WHERE b.conqueror_id IS NOT NULL AND (b.location <-> p.location) < spawn_min
		            AND (SELECT count(*) FROM ship s WHERE s.player_id = b.conqueror_id AND NOT s.destroyed) > median_ships))
		 ORDER BY RANDOM() LIMIT 1;
		IF home IS NULL THEN  -- nowhere far enough away; take any free planet rather than refuse the player
			SELECT id INTO home FROM planet WHERE conqueror_id IS NULL ORDER BY RANDOM() LIMIT 1;
		END IF;
		UPDATE planet SET conqueror_id=NEW.id, mine_limit=50, fuel=3000000, difficulty=10 WHERE id = home;
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
		FROM generate_series(1,50)
		LOOP
			IF NOT EXISTS (SELECT 1 FROM planet WHERE (location <-> new_planet.location) <= 3000)
			   AND (spawn_min <= 0 OR NOT EXISTS (
			         SELECT 1 FROM planet b WHERE b.conqueror_id IS NOT NULL AND (b.location <-> new_planet.location) < spawn_min
			            AND (SELECT count(*) FROM ship s WHERE s.player_id = b.conqueror_id AND NOT s.destroyed) > median_ships)) THEN
				INSERT INTO planet(id, name, mine_limit, difficulty, fuel, location, location_x, location_y, conqueror_id)
					VALUES(new_planet.id, new_planet.name, new_planet.mine_limit, new_planet.difficulty, new_planet.fuel, new_planet.location,new_planet.location[0],new_planet.location[1], NEW.id);
				EXIT;
			END IF;
		END LOOP;
	END IF;

	INSERT INTO player_round_stats(player_id, round_id) VALUES (NEW.id, (select last_value from round_seq)) ON CONFLICT DO NOTHING;
	INSERT INTO player_overall_stats(player_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;

RETURN NEW;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp
  COST 100;

COMMIT;
