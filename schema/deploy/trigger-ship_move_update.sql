-- Deploy trigger-ship_move_update
-- requires: table-ship
-- requires: table-ship_flight_recorder

BEGIN;

CREATE OR REPLACE FUNCTION ship_move_update()
  RETURNS trigger AS
$BODY$
BEGIN
  IF NOT NEW.location ~= OLD.location THEN
    INSERT INTO ship_flight_recorder(ship_id, tic, location, player_id) VALUES(NEW.id, (SELECT last_value FROM tic_seq), NEW.location, NEW.player_id);
  END IF;
  RETURN NULL;
END $BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE TRIGGER ship_move_update
  AFTER UPDATE
  ON ship
  FOR EACH ROW
  EXECUTE PROCEDURE ship_move_update();

COMMIT;
