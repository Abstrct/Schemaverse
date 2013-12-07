-- Revert function-run_fleet_script

BEGIN;

DROP FUNCTION run_fleet_script(integer);

COMMIT;
