-- Verify view-ships_in_range

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'ships_in_range';

ROLLBACK;
