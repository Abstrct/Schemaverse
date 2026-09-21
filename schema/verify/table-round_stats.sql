-- Verify table-round_stats

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'round_stats';

ROLLBACK;
