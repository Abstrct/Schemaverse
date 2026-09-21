-- Verify view-current_stats

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'current_stats';

ROLLBACK;
