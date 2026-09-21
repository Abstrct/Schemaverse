-- Verify function-refuel_ship

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'not your ship' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'refuel_ship';

ROLLBACK;
