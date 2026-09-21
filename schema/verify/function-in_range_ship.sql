-- Verify function-in_range_ship

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'in_range_ship';

ROLLBACK;
