-- Revert trigger-update_planet

BEGIN;

DROP TRIGGER update_planet ON planet;

DROP FUNCTION update_planet();

COMMIT;
