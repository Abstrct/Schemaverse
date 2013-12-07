-- Revert trigger-id_dealer

BEGIN;


DROP TRIGGER trophy_id_dealer ON trophy;
DROP TRIGGER player_id_dealer ON player;
DROP TRIGGER ship_id_dealer ON ship;
DROP TRIGGER fleet_id_dealer ON fleet;
DROP TRIGGER event_id_dealer ON event;

DROP FUNCTION id_dealer();


COMMIT;
