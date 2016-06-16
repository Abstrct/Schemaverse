-- Revert trigger-ship_move_update

BEGIN;

DROP TRIGGER ship_move_update ON ship;

DROP FUNCTION ship_move_update();

COMMIT;
