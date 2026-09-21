-- Deploy fleet-shared
-- requires: table-fleet
-- requires: view-my_fleets
-- requires: rls-policies
-- requires: views-security_invoker
--
-- A fleet script is private until its owner says otherwise. UPDATE my_fleets
-- SET shared = true publishes it: it appears in shared_fleets, which every
-- player (and the spectator role behind the public web pages) can read, with
-- the author's name. The script is the thing being shared; ship counts and
-- purchased runtime stay private. Flipping shared back off unpublishes it.

BEGIN;

ALTER TABLE fleet ADD COLUMN shared boolean NOT NULL DEFAULT false;
ALTER TABLE fleet ADD COLUMN shared_at timestamptz;

CREATE OR REPLACE FUNCTION fleet_share_stamp() RETURNS trigger AS
$$
BEGIN
	IF NEW.shared AND NOT OLD.shared THEN
		NEW.shared_at := now();
	ELSIF NOT NEW.shared THEN
		NEW.shared_at := NULL;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql SET search_path = public, pg_temp;

CREATE TRIGGER fleet_share_stamp
	BEFORE UPDATE OF shared ON fleet
	FOR EACH ROW EXECUTE FUNCTION fleet_share_stamp();

GRANT UPDATE (shared) ON fleet TO players;

-- my_fleets grows a shared column; the update rule carries it through.
CREATE OR REPLACE VIEW my_fleets AS
	SELECT fleet.id, fleet.name, fleet.script, fleet.script_declarations, fleet.last_script_update_tic, fleet.enabled, fleet.runtime, fleet.shared
	  FROM fleet
	 WHERE fleet.player_id = get_player_id("session_user"());
ALTER VIEW my_fleets SET (security_invoker = true);

CREATE OR REPLACE RULE fleet_update AS
	ON UPDATE TO my_fleets DO INSTEAD
	UPDATE fleet SET name = new.name, script = new.script, script_declarations = new.script_declarations, enabled = new.enabled, shared = new.shared
	 WHERE fleet.id = new.id;

-- Owner-run on purpose: it must see every player's shared rows.
CREATE VIEW shared_fleets AS
	SELECT f.id, f.name, f.script, f.script_declarations, f.last_script_update_tic, f.enabled, f.shared_at,
	       f.player_id, p.username, p.symbol, p.rgb
	  FROM fleet f
	  JOIN player p ON p.id = f.player_id
	 WHERE f.shared;
COMMENT ON VIEW shared_fleets IS 'Fleet scripts their owners have published with UPDATE my_fleets SET shared = true.';
GRANT SELECT ON shared_fleets TO players;

COMMIT;
