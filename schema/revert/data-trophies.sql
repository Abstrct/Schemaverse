-- Revert data-trophies

BEGIN;

DO $$
DECLARE t record;
BEGIN
	FOR t IN SELECT id FROM trophy WHERE creator = 0 LOOP
		EXECUTE format('DROP FUNCTION IF EXISTS trophy_script_%s(integer)', t.id);
	END LOOP;
END $$;
DELETE FROM player_trophy WHERE trophy_id IN (SELECT id FROM trophy WHERE creator = 0);
DELETE FROM trophy WHERE creator = 0;
ALTER TABLE trophy DISABLE TRIGGER trophy_script_update;

COMMIT;
