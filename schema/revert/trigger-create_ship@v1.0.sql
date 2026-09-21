-- Revert trigger-create_ship

BEGIN;

DROP TRIGGER create_ship ON ship;

DROP FUNCTION create_ship();

COMMIT;
