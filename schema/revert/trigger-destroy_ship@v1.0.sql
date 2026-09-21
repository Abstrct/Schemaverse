-- Revert trigger-destroy_ship

BEGIN;

DROP TRIGGER destroy_ship ON ship;

DROP FUNCTION destroy_ship();

COMMIT;
