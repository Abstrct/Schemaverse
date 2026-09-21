-- Verify view-my_player@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'my_player';

ROLLBACK;
