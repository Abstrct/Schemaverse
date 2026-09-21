-- Verify view-trophy_case

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'trophy_case';

ROLLBACK;
