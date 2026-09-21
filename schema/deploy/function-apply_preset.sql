-- Deploy function-apply_preset
-- requires: data-gameplay_variables
--
-- One call to set every gameplay lever. Owner only.
--
--   classic    the 2011-2016 rules: no upkeep, flat prices, no protection
--   public     the levers on, tuned for a long-running server with veterans
--   classroom  short rounds, generous, protected: an hour-long round for a class

BEGIN;

CREATE OR REPLACE FUNCTION apply_preset(preset text) RETURNS text AS
$BODY$
DECLARE
	v jsonb;
	k text;
BEGIN
	IF SESSION_USER <> 'schemaverse' THEN
		RAISE EXCEPTION 'apply_preset() is for the game owner';
	END IF;
	v := CASE preset
		WHEN 'classic' THEN '{"SHIP_UPKEEP":0,"UPGRADE_PRICE_SCALE":0,"SPAWN_MIN_DISTANCE":0,"GRACE_TICS":0,"HOME_SAFE_RADIUS":5000,
		                     "LATE_JOIN_STIPEND":0,"LATE_JOIN_FUEL":0,"PLANET_REGEN_SMALL_BONUS":0,"MAX_SHIPS":1000,
		                     "ROUND_LENGTH":"1 days"}'::jsonb
		WHEN 'public' THEN '{"SHIP_UPKEEP":2,"UPGRADE_PRICE_SCALE":100,"SPAWN_MIN_DISTANCE":200000,"GRACE_TICS":300,"HOME_SAFE_RADIUS":5000,
		                     "LATE_JOIN_STIPEND":20000,"LATE_JOIN_FUEL":200000,"PLANET_REGEN_SMALL_BONUS":50,"MAX_SHIPS":1000,
		                     "ROUND_LENGTH":"7 days"}'::jsonb
		WHEN 'classroom' THEN '{"SHIP_UPKEEP":0,"UPGRADE_PRICE_SCALE":0,"SPAWN_MIN_DISTANCE":100000,"GRACE_TICS":60,"HOME_SAFE_RADIUS":10000,
		                     "LATE_JOIN_STIPEND":50000,"LATE_JOIN_FUEL":500000,"PLANET_REGEN_SMALL_BONUS":100,"MAX_SHIPS":100,
		                     "ROUND_LENGTH":"1 hours"}'::jsonb
		ELSE NULL END;
	IF v IS NULL THEN
		RAISE EXCEPTION 'unknown preset %; use classic, public or classroom', preset;
	END IF;
	FOR k IN SELECT jsonb_object_keys(v) LOOP
		IF jsonb_typeof(v->k) = 'number' THEN
			UPDATE variable SET numeric_value = (v->>k)::integer WHERE name = k AND player_id = 0;
		ELSE
			UPDATE variable SET char_value = v->>k WHERE name = k AND player_id = 0;
		END IF;
	END LOOP;
	RETURN format('preset %s applied: %s', preset, v::text);
END
$BODY$ LANGUAGE plpgsql VOLATILE SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION apply_preset(text) FROM PUBLIC;

COMMIT;
