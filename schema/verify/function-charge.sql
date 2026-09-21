-- Verify function-charge

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'charge';

ROLLBACK;
