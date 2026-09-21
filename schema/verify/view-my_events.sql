-- Verify view-my_events

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'my_events';

ROLLBACK;
