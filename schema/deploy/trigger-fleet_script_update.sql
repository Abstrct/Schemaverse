-- Deploy trigger-fleet_script_update
-- requires: trigger-fleet_script_update@v1.0
--
-- Rework: the dollar-quote tag that wraps a player's script body used to be
-- 'fleet_script_' plus a random number below a million, guarded by a LIKE
-- check. A uuid tag cannot be guessed or matched, so the guard goes and the
-- quote cannot be closed from inside the script. Identifiers go through format().

BEGIN;

CREATE OR REPLACE FUNCTION fleet_script_update()
  RETURNS trigger AS
$BODY$
DECLARE
	player_username character varying;
	tag text;
	current_tic integer;
BEGIN
	IF ((NEW.script = OLD.script) AND (NEW.script_declarations = OLD.script_declarations)) THEN
		RETURN NEW;
	END IF;

	SELECT last_value INTO current_tic FROM tic_seq;

	IF NEW.last_script_update_tic = current_tic THEN
		NEW.script := OLD.script;
		NEW.script_declarations := OLD.script_declarations;
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Fleet scripts can only be updated once a tic. While you wait why not brush up on your PL/pgSQL skills? '';';
		RETURN NEW;
	END IF;

	NEW.last_script_update_tic := current_tic;

	tag := 'fs_' || replace(gen_random_uuid()::text, '-', '');
	EXECUTE format('CREATE OR REPLACE FUNCTION fleet_script_%s() RETURNS boolean AS $%s$
	DECLARE
		this_fleet_id integer;
		this_fleet_script_start timestamptz;
		%s
	BEGIN
		this_fleet_script_start := current_timestamp;
		this_fleet_id := %s;
		%s
	RETURN 1;
	END $%s$ LANGUAGE plpgsql;',
		NEW.id, tag, NEW.script_declarations, NEW.id, NEW.script, tag);

	SELECT GET_PLAYER_USERNAME(player_id) INTO player_username FROM fleet WHERE id=NEW.id;
	EXECUTE format('REVOKE ALL ON FUNCTION fleet_script_%s() FROM PUBLIC', NEW.id);
	EXECUTE format('REVOKE ALL ON FUNCTION fleet_script_%s() FROM players', NEW.id);
	EXECUTE format('GRANT EXECUTE ON FUNCTION fleet_script_%s() TO %I', NEW.id, player_username);

	RETURN NEW;
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  SET search_path = public, pg_temp
  COST 100;

COMMIT;
