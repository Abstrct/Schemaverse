-- Revert trigger-trophy_script_update

BEGIN;

DROP TRIGGER trophy_script_update ON trophy;

DROP FUNCTION trophy_script_update();

COMMIT;
