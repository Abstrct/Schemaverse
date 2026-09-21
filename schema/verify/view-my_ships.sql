-- Verify view-my_ships

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'my_ships';

ROLLBACK;
