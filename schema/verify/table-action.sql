-- Verify table-action

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'action';

ROLLBACK;
