-- Verify function-mine

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'mine';

ROLLBACK;
