-- Verify view-current_player_stats

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'current_player_stats';

ROLLBACK;
