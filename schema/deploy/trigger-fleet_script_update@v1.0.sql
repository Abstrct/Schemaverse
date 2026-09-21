-- Deploy trigger-fleet_script_update
-- requires: table-fleet

BEGIN;


CREATE OR REPLACE FUNCTION fleet_script_update()
  RETURNS trigger AS
$BODY$
DECLARE
	player_username character varying;
	secret character varying;
	current_tic integer;
BEGIN
	IF ((NEW.script = OLD.script) AND (NEW.script_declarations = OLD.script_declarations)) THEN
		RETURN NEW;
	END IF;

	SELECT last_value INTO current_tic FROM tic_seq;


	IF NEW.script LIKE '%$fleet_script_%' OR  NEW.script_declarations LIKE '%$fleet_script_%' THEN
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''TILT!'';';
		RETURN NEW;
	END IF;

	IF NEW.last_script_update_tic = current_tic THEN
		NEW.script := OLD.script;
		NEW.script_declarations := OLD.script_declarations;
		EXECUTE 'NOTIFY ' || get_player_error_channel() ||', ''Fleet scripts can only be updated once a tic. While you wait why not brush up on your PL/pgSQL skills? '';';
		RETURN NEW;
	END IF;

	NEW.last_script_update_tic := current_tic;

	--secret to stop SQL injections here
	secret := 'fleet_script_' || (RANDOM()*1000000)::integer;
	EXECUTE 'CREATE OR REPLACE FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() RETURNS boolean as $'||secret||'$
	DECLARE
		this_fleet_id integer;
		this_fleet_script_start timestamptz;
		' || NEW.script_declarations || '
	BEGIN
		this_fleet_script_start := current_timestamp;
		this_fleet_id := '|| NEW.id||';
		' || NEW.script || '
	RETURN 1;
	END $'||secret||'$ LANGUAGE plpgsql;'::TEXT;
	
	SELECT GET_PLAYER_USERNAME(player_id) INTO player_username FROM fleet WHERE id=NEW.id;
	EXECUTE 'REVOKE ALL ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() FROM PUBLIC'::TEXT;
	EXECUTE 'REVOKE ALL ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() FROM players'::TEXT;
	EXECUTE 'GRANT EXECUTE ON FUNCTION FLEET_SCRIPT_'|| NEW.id ||'() TO '|| player_username ||''::TEXT;
	
	RETURN NEW;
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER FLEET_SCRIPT_UPDATE BEFORE UPDATE ON fleet
  FOR EACH ROW EXECUTE PROCEDURE FLEET_SCRIPT_UPDATE();  

COMMIT;
