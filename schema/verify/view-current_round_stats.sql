-- Verify view-current_round_stats

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'current_round_stats';

ROLLBACK;
