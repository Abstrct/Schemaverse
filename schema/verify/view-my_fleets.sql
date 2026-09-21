-- Verify view-my_fleets

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'my_fleets';

ROLLBACK;
