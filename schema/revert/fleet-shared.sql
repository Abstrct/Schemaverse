-- Revert fleet-shared

BEGIN;

DROP VIEW shared_fleets;
DROP VIEW my_fleets;

CREATE VIEW my_fleets AS
	SELECT fleet.id, fleet.name, fleet.script, fleet.script_declarations, fleet.last_script_update_tic, fleet.enabled, fleet.runtime
	  FROM fleet
	 WHERE fleet.player_id = get_player_id("session_user"());
ALTER VIEW my_fleets SET (security_invoker = true);
CREATE RULE fleet_insert AS
	ON INSERT TO my_fleets DO INSTEAD
	INSERT INTO fleet (player_id, name) VALUES (get_player_id("session_user"()), new.name);
CREATE RULE fleet_update AS
	ON UPDATE TO my_fleets DO INSTEAD
	UPDATE fleet SET name = new.name, script = new.script, script_declarations = new.script_declarations, enabled = new.enabled
	 WHERE fleet.id = new.id;
GRANT SELECT, INSERT, UPDATE ON my_fleets TO players;

DROP TRIGGER fleet_share_stamp ON fleet;
DROP FUNCTION fleet_share_stamp();
ALTER TABLE fleet DROP COLUMN shared_at;
ALTER TABLE fleet DROP COLUMN shared;

COMMIT;
