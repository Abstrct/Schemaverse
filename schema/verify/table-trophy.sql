-- Verify table-trophy

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'trophy';

ROLLBACK;
