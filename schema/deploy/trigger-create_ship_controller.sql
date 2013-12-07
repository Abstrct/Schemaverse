-- Deploy trigger-create_ship_controller
-- requires: table-ship
-- requires: table-ship_control

BEGIN;

CREATE OR REPLACE FUNCTION create_ship_controller()
  RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO ship_control(ship_id, player_id) VALUES(NEW.id, NEW.player_id);
	RETURN NEW;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;


CREATE TRIGGER create_ship_controller
  AFTER INSERT
  ON ship
  FOR EACH ROW
  EXECUTE PROCEDURE create_ship_controller();

COMMIT;
