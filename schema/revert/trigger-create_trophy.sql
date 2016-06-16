-- Revert trigger-create_trophy

BEGIN;

DROP TRIGGER create_trophy ON trophy;

DROP FUNCTION create_trophy();

COMMIT;
