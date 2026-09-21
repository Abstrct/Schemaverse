-- Verify function-disable_fleet@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'disable_fleet';

ROLLBACK;
