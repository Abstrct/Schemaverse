-- Revert trigger-create_ship_controller

BEGIN;

 DROP TRIGGER create_ship_controller ON ship;

 DROP FUNCTION create_ship_controller();

COMMIT;
