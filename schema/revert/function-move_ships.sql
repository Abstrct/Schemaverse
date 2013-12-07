-- Revert function-move_ships

BEGIN;

DROP FUNCTION move_ships();

COMMIT;
