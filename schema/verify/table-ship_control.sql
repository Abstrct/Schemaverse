-- Verify table-ship_control

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ship_control';

ROLLBACK;
