-- Verify view-planets

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'planets';

ROLLBACK;
