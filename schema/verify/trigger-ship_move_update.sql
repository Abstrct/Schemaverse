-- Verify trigger-ship_move_update

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'ship_move_update';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'ship_move_update';

ROLLBACK;
