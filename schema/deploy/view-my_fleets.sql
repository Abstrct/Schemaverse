-- Deploy view-my_fleets
-- requires: table-fleet

BEGIN;


CREATE OR REPLACE VIEW my_fleets AS 
	SELECT fleet.id, fleet.name, fleet.script, fleet.script_declarations, fleet.last_script_update_tic, fleet.enabled, fleet.runtime
			FROM fleet
			WHERE fleet.player_id = get_player_id("session_user"());


CREATE OR REPLACE RULE fleet_insert AS
    ON INSERT TO my_fleets DO INSTEAD  INSERT INTO fleet (player_id, name) 
  VALUES (get_player_id("session_user"()), new.name);


CREATE OR REPLACE RULE fleet_update AS
    ON UPDATE TO my_fleets DO INSTEAD  UPDATE fleet SET name = new.name, script = new.script, script_declarations = new.script_declarations, enabled = new.enabled
  WHERE fleet.id = new.id;


COMMIT;
