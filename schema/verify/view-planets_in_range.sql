-- Verify view-planets_in_range

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'planets_in_range';

ROLLBACK;
