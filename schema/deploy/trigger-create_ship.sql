-- Deploy trigger-create_ship
-- requires: trigger-create_ship@v1.0
--
-- Rework:
--   * the ship cap comes from the MAX_SHIPS variable instead of a hardcoded 2000
--   * the skill-total message says what is actually checked (<= 20)
--   * a ship placed somewhere other than one of the player's planets is rejected.
--     Omitting the location still means "spawn at my home planet".

BEGIN;

CREATE OR REPLACE FUNCTION create_ship()
  RETURNS trigger AS
$BODY$
BEGIN
	NEW.current_health = 100;
	NEW.max_health = 100;
	NEW.current_fuel = 100;
	NEW.max_fuel = 100;
	NEW.max_speed = 1000;

	IF (SELECT COUNT(*) FROM ship WHERE player_id=NEW.player_id AND NOT destroyed) >= GET_NUMERIC_VARIABLE('MAX_SHIPS') THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''A player can only have '|| GET_NUMERIC_VARIABLE('MAX_SHIPS') ||' ships (MAX_SHIPS) in their fleet'';';
		RETURN NULL;
	END IF;

	IF (LEAST(NEW.attack, NEW.defense, NEW.engineering, NEW.prospecting) < 0 ) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, Attack Defense Engineering and Prospecting cannot be values lower than zero'';';
		RETURN NULL;
	END IF;

	IF (NEW.attack + NEW.defense + NEW.engineering + NEW.prospecting) > 20 THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''When creating a new ship, (Attack + Defense + Engineering + Prospecting) must be 20 or less'';';
		RETURN NULL;
	END IF;

	-- Backwards compatibility: accept either the point or the x/y pair
	IF NEW.location IS NULL THEN
		NEW.location := POINT(NEW.location_x, NEW.location_y);
	END IF;

	IF NEW.location IS NULL THEN
		-- No location given: spawn at one of the player's planets
		SELECT location INTO NEW.location FROM planets WHERE conqueror_id=NEW.player_id LIMIT 1;
		IF NEW.location IS NULL THEN
			EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Lost all your planets. Unable to create new ships.'';';
			RETURN NULL;
		END IF;
	ELSIF NOT EXISTS (SELECT 1 FROM planets p WHERE p.location ~= NEW.location AND p.conqueror_id = NEW.player_id) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''New ship MUST be created on a planet your player has conquered'';';
		RETURN NULL;
	END IF;

	NEW.location_x := NEW.location[0];
	NEW.location_y := NEW.location[1];

	IF NOT CHARGE('SHIP', 1) THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Not enough funds to purchase ship'';';
		RETURN NULL;
	END IF;

	NEW.last_move_tic := (SELECT last_value FROM tic_seq);

	RETURN NEW;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp
  COST 100;

COMMIT;
