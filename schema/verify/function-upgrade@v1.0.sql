-- Verify function-upgrade@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'upgrade';

ROLLBACK;
