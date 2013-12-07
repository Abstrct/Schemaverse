-- Revert trigger-general_permission_check

BEGIN;

DROP TRIGGER a_ship_permission_check ON ship;
DROP TRIGGER a_ship_control_permission_check ON ship_control;
DROP TRIGGER a_fleet_permission_check ON fleet;

DROP FUNCTION general_permission_check();

COMMIT;
