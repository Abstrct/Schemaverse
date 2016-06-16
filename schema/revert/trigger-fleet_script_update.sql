-- Revert trigger-fleet_script_update

BEGIN;

DROP TRIGGER fleet_script_update ON fleet;

DROP FUNCTION fleet_script_update();

COMMIT;
