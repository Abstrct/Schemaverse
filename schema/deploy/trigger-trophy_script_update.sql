-- Deploy trigger-trophy_script_update
-- requires: trigger-trophy_script_update@v1.0
--
-- Rework: uuid dollar-quote tag, identifiers through format(). The trigger
-- stays disabled by default exactly as before; enabling trophy approval is a
-- separate decision.

BEGIN;

CREATE OR REPLACE FUNCTION trophy_script_update()
  RETURNS trigger AS
$BODY$
DECLARE
	tag text;
	player_id integer;
BEGIN
	player_id := GET_PLAYER_ID(SESSION_USER);

	IF SESSION_USER = 'schemaverse' THEN
		IF NEW.approved='t' AND OLD.approved='f' THEN
			IF NEW.round_started=0 THEN
				SELECT last_value INTO NEW.round_started FROM round_seq;
			END IF;

			tag := 'ts_' || replace(gen_random_uuid()::text, '-', '');
			EXECUTE format('CREATE OR REPLACE FUNCTION trophy_script_%s(_round_id integer) RETURNS SETOF trophy_winner AS $%s$
			DECLARE
				this_trophy_id integer;
				this_round integer; -- Deprecated, use _round_id in your script instead
				winner trophy_winner%%rowtype;
				%s
			BEGIN
				this_trophy_id := %s;
				SELECT last_value INTO this_round FROM round_seq;
				%s
				RETURN;
			END $%s$ LANGUAGE plpgsql;',
				NEW.id, tag, NEW.script_declarations, NEW.id, NEW.script, tag);

			EXECUTE format('REVOKE ALL ON FUNCTION trophy_script_%s(integer) FROM PUBLIC', NEW.id);
			EXECUTE format('REVOKE ALL ON FUNCTION trophy_script_%s(integer) FROM players', NEW.id);
			EXECUTE format('GRANT EXECUTE ON FUNCTION trophy_script_%s(integer) TO schemaverse', NEW.id);
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

COMMIT;
