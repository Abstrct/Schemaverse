-- Verify function-in_range_planet

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'in_range_planet';

ROLLBACK;
