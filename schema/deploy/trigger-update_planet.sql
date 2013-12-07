-- Deploy trigger-update_planet
-- requires: table-planet

BEGIN;

CREATE OR REPLACE FUNCTION update_planet()
  RETURNS trigger AS
$BODY$
BEGIN
	IF NEW.conqueror_id!=OLD.conqueror_id THEN
		INSERT INTO event(action, player_id_1, player_id_2, referencing_id, location, public, tic)
			VALUES('CONQUER',NEW.conqueror_id,OLD.conqueror_id, NEW.id , NEW.location, 't',(SELECT last_value FROM tic_seq));
	END IF;
	RETURN NEW;	
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER update_planet
  AFTER UPDATE
  ON planet
  FOR EACH ROW
  EXECUTE PROCEDURE update_planet();

COMMIT;
