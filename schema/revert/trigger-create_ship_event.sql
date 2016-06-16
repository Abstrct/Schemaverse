-- Revert trigger-create_ship_event

BEGIN;

 DROP TRIGGER create_ship_event ON ship;
 
 DROP FUNCTION create_ship_event();

COMMIT;
