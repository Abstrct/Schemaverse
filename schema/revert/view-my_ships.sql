-- Revert view-my_ships

BEGIN;

 DROP RULE ship_control_update ON my_ships;

 DROP RULE ship_delete ON my_ships;

 DROP RULE ship_insert ON my_ships;

 DROP VIEW my_ships;

COMMIT;
