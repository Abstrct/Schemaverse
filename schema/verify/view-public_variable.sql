-- Verify view-public_variable

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'public_variable';

ROLLBACK;
