-- Verify function-move_ships

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'move_ships';

ROLLBACK;
