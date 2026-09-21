-- Verify function-refuel_ship@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'refuel_ship';

ROLLBACK;
