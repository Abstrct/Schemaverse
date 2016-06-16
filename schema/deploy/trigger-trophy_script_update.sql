-- Deploy trigger-trophy_script_update
-- requires: table-trophy
-- requires: type-trophy_winner

BEGIN;


CREATE OR REPLACE FUNCTION trophy_script_update()
  RETURNS trigger AS
$BODY$
DECLARE
       current_round integer;
	secret character varying;

	player_id integer;
BEGIN

	player_id := GET_PLAYER_ID(SESSION_USER);

	IF  SESSION_USER = 'schemaverse' THEN
	       IF NEW.approved='t' AND OLD.approved='f' THEN
			IF NEW.round_started=0 THEN
				SELECT last_value INTO NEW.round_started FROM round_seq;
			END IF;

		        secret := 'trophy_script_' || (RANDOM()*1000000)::integer;
       		 EXECUTE 'CREATE OR REPLACE FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(_round_id integer) RETURNS SETOF trophy_winner AS $'||secret||'$
		        DECLARE
				this_trophy_id integer;
				this_round integer; -- Deprecated, use _round_id in your script instead
				 winner trophy_winner%rowtype;
       		         ' || NEW.script_declarations || '
		        BEGIN
       		         this_trophy_id := '|| NEW.id||';
       		         SELECT last_value INTO this_round FROM round_seq; 
	       	         ' || NEW.script || '
			 RETURN;
	       	 END $'||secret||'$ LANGUAGE plpgsql;'::TEXT;

		 EXECUTE 'REVOKE ALL ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) FROM PUBLIC'::TEXT;
       		 EXECUTE 'REVOKE ALL ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) FROM players'::TEXT;
		 EXECUTE 'GRANT EXECUTE ON FUNCTION TROPHY_SCRIPT_'|| NEW.id ||'(integer) TO schemaverse'::TEXT;
		END IF;
	ELSEIF NOT player_id = OLD.creator THEN
		RETURN OLD;
	ELSE 
		IF NOT OLD.approved = NEW.approved THEN
			NEW.approved='f';
		END IF;

		IF NOT ((NEW.script = OLD.script) AND (NEW.script_declarations = OLD.script_declarations)) THEN
			NEW.approved='f';	         
	       END IF;
	END IF;

       RETURN NEW;
END $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER trophy_script_update
  BEFORE UPDATE
  ON trophy
  FOR EACH ROW
  EXECUTE PROCEDURE trophy_script_update();
ALTER TABLE trophy DISABLE TRIGGER trophy_script_update;

COMMIT;
