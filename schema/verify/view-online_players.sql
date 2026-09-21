-- Verify view-online_players

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'online_players';

ROLLBACK;
