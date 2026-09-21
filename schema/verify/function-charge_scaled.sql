-- Verify function-charge_scaled

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'charge' AND pronargs = 3;

ROLLBACK;
