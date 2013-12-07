-- Deploy trigger-create_ship_event
-- requires: table-ship

BEGIN;

CREATE OR REPLACE FUNCTION create_ship_event()
  RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO ship_flight_recorder(ship_id, tic, location, player_id) VALUES(NEW.id, (SELECT last_value FROM tic_seq)-1, NEW.location, NEW.player_id);

	INSERT INTO event(action, player_id_1, ship_id_1, location, public, tic)
		VALUES('BUY_SHIP',NEW.player_id, NEW.id, NEW.location, 'f',(SELECT last_value FROM tic_seq));
	RETURN NULL; 
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER
  COST 100;

CREATE TRIGGER create_ship_event
  AFTER INSERT
  ON ship
  FOR EACH ROW
  EXECUTE PROCEDURE create_ship_event();

COMMIT;
