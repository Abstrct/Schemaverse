-- Verify function-repair

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'repair';

ROLLBACK;
