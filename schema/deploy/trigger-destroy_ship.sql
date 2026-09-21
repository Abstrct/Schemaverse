-- Deploy trigger-destroy_ship
-- requires: trigger-destroy_ship@v1.0
--
-- Rework: the v1.0 trigger deleted from ships_near_planets and ships_near_ships,
-- cache tables that were dropped before the sqitch conversion. PL/pgSQL resolves
-- table names at run time, so the first destroyed ship raised "relation does not
-- exist" inside the tic's health pass and rolled it back. The trigger itself
-- already exists; only the function body changes.

BEGIN;

CREATE OR REPLACE FUNCTION destroy_ship()
  RETURNS trigger AS
$BODY$
BEGIN
	IF ( NOT OLD.destroyed = NEW.destroyed ) AND NEW.destroyed='t' THEN
		UPDATE player SET balance=balance+(select cost from price_list where code='SHIP') WHERE id=OLD.player_id;

		INSERT INTO event(action, player_id_1, ship_id_1, location, public, tic)
			VALUES('EXPLODE',NEW.player_id, NEW.id, NEW.location, 't',(SELECT last_value FROM tic_seq));

	END IF;
	RETURN NULL;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

COMMIT;
