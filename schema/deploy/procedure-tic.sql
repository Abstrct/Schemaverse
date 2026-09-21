-- Deploy procedure-tic
-- requires: procedure-tic@v1.3
-- requires: data-gameplay_variables
-- requires: table-mission
--
-- Rework: tic_close() runs the economy phase (regeneration, upkeep) through
-- tic_economy() and checks missions every MISSION_CHECK_EVERY tics.

BEGIN;

-- Phase: economy. Deterministic planet regeneration (with a bonus for
-- planets held by small fleets) and ship upkeep. Both are variables; see
-- data-gameplay_variables.
CREATE OR REPLACE FUNCTION tic_economy(this_tic integer) RETURNS integer AS
$BODY$
DECLARE
	regen numeric := GET_NUMERIC_VARIABLE('PLANET_REGEN_PER_TIC');
	cap numeric := GET_NUMERIC_VARIABLE('PLANET_REGEN_CAP');
	bonus numeric := COALESCE(GET_NUMERIC_VARIABLE('PLANET_REGEN_SMALL_BONUS'), 0);
	upkeep numeric := COALESCE(GET_NUMERIC_VARIABLE('SHIP_UPKEEP'), 0);
	median_ships numeric;
	n integer := 0;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'tic_economy() is for the game owner';
	END IF;

	SELECT COALESCE(percentile_cont(0.5) WITHIN GROUP (ORDER BY c), 0) INTO median_ships
	  FROM (SELECT count(*)::numeric AS c FROM ship WHERE NOT destroyed AND player_id > 0 GROUP BY player_id) t;

	IF regen > 0 THEN
		UPDATE planet p SET fuel = LEAST(cap, p.fuel + regen * CASE
				WHEN bonus > 0 AND p.conqueror_id IS NOT NULL
				     AND (SELECT count(*) FROM ship s WHERE s.player_id = p.conqueror_id AND NOT s.destroyed) < median_ships
				THEN (100 + bonus) / 100.0 ELSE 1 END)::integer
		 WHERE p.fuel < cap;
	END IF;

	IF upkeep > 0 THEN
		WITH bill AS (
			SELECT s.player_id, count(*) * upkeep AS due, GREATEST(0, count(*) * upkeep - pl.fuel_reserve) AS short
			  FROM ship s JOIN player pl ON pl.id = s.player_id
			 WHERE NOT s.destroyed AND s.player_id > 0
			 GROUP BY s.player_id, pl.fuel_reserve
		), paid AS (
			UPDATE player pl SET fuel_reserve = GREATEST(0, pl.fuel_reserve - b.due)
			  FROM bill b WHERE pl.id = b.player_id
			 RETURNING b.player_id, b.short
		)
		-- Whoever could not pay from the reserve pays from the tanks.
		UPDATE ship s SET current_fuel = GREATEST(0, s.current_fuel - upkeep::integer)
		  FROM paid WHERE paid.player_id = s.player_id AND paid.short > 0 AND NOT s.destroyed;
		GET DIAGNOSTICS n = ROW_COUNT;
	END IF;
	RETURN n;
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;
REVOKE ALL ON FUNCTION tic_economy(integer) FROM PUBLIC;

-- Phase: ship actions queued in ship_control (ATTACK / REPAIR / MINE).
CREATE OR REPLACE FUNCTION tic_actions() RETURNS integer AS
$BODY$
DECLARE n integer;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'tic_actions() is for the game owner';
	END IF;
	PERFORM CASE
			WHEN ship_control.action = 'ATTACK' THEN ATTACK(ship.id, ship_control.action_target_id)::integer
			WHEN ship_control.action = 'REPAIR' THEN REPAIR(ship.id, ship_control.action_target_id)::integer
			WHEN ship_control.action = 'MINE'   THEN MINE(ship.id, ship_control.action_target_id)::integer
			ELSE NULL END
		FROM ship, ship_control
		WHERE ship.id = ship_control.ship_id
		  AND ship_control.action IS NOT NULL
		  AND ship_control.action_target_id IS NOT NULL
		  AND NOT ship.destroyed
		  AND ship.last_action_tic <> (SELECT last_value FROM tic_seq);
	GET DIAGNOSTICS n = ROW_COUNT;
	RETURN n;
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;

-- Phase: settle health. future_health accumulates damage and repairs during
-- the tic; here it becomes current_health, clamped to [0, max_health]. Ships
-- at zero health for more than EXPLODED tics are destroyed (the destroy_ship
-- trigger refunds and logs EXPLODE).
--
-- Note: tic.pl only copied future_health into current_health when the ship
-- was already below max_health, so a full-health ship showed no damage until
-- it died. That was a bug; damage is visible immediately now.
CREATE OR REPLACE FUNCTION tic_health(this_tic integer) RETURNS integer AS
$BODY$
DECLARE exploded integer; n integer;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'tic_health() is for the game owner';
	END IF;
	exploded := GET_NUMERIC_VARIABLE('EXPLODED');

	UPDATE ship SET
		future_health   = LEAST(future_health, max_health),
		current_health  = GREATEST(0, LEAST(future_health, max_health)),
		last_living_tic = CASE WHEN LEAST(future_health, max_health) > 0 THEN this_tic ELSE last_living_tic END
	WHERE NOT destroyed;

	UPDATE ship SET destroyed = true
	WHERE NOT destroyed AND player_id > 0 AND current_health <= 0
	  AND (this_tic - last_living_tic) > exploded;
	GET DIAGNOSTICS n = ROW_COUNT;
	RETURN n;
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;

CREATE OR REPLACE PROCEDURE tic_open() AS
$BODY$
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'tic_open() is for the game owner';
	END IF;
	PERFORM round_control();
	PERFORM ensure_event_partition(current_round());
	COMMIT;

	LOCK TABLE ship, ship_control IN EXCLUSIVE MODE;
	PERFORM move_ships();
	COMMIT;
END
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE tic_close() AS
$BODY$
DECLARE this_tic integer;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'tic_close() is for the game owner';
	END IF;
	SELECT last_value INTO this_tic FROM tic_seq;

	LOCK TABLE ship, ship_control IN EXCLUSIVE MODE;
	PERFORM tic_actions();
	COMMIT;

	LOCK TABLE planet_miners IN EXCLUSIVE MODE;
	PERFORM perform_mining();
	COMMIT;

	PERFORM tic_economy(this_tic);
	COMMIT;

	LOCK TABLE ship, ship_control IN EXCLUSIVE MODE;
	PERFORM tic_health(this_tic);
	COMMIT;

	IF this_tic % 5 = 0 THEN
		REFRESH MATERIALIZED VIEW CONCURRENTLY player_stats;
		COMMIT;
	END IF;

	IF this_tic % GREATEST(1, COALESCE(GET_NUMERIC_VARIABLE('MISSION_CHECK_EVERY'), 5)) = 0 THEN
		PERFORM check_all_missions();
		COMMIT;
	END IF;

	INSERT INTO event(player_id_1, action, tic, public) VALUES (0, 'TIC', this_tic, true);
	PERFORM nextval('tic_seq');
	PERFORM pg_notify('tic', (this_tic + 1)::text);
	COMMIT;
END
$BODY$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION tic_actions() FROM PUBLIC;
REVOKE ALL ON FUNCTION tic_health(integer) FROM PUBLIC;
REVOKE ALL ON PROCEDURE tic_open() FROM PUBLIC;
REVOKE ALL ON PROCEDURE tic_close() FROM PUBLIC;

COMMIT;
