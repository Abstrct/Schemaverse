-- Revert procedure-tic to procedure-tic@v1.1

BEGIN;

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

	-- Planet renewal. Same random top-up tic.pl did; Phase 4 replaces it with
	-- something that favours smaller players.
	UPDATE planet SET fuel = fuel + 1000000
	 WHERE id IN (SELECT id FROM planet WHERE fuel < 10000000 ORDER BY random() LIMIT 5000);
	COMMIT;

	LOCK TABLE ship, ship_control IN EXCLUSIVE MODE;
	PERFORM tic_health(this_tic);
	COMMIT;

	IF this_tic % 5 = 0 THEN
		REFRESH MATERIALIZED VIEW CONCURRENTLY player_stats;
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
