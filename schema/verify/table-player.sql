-- Verify table-player

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'player';

ROLLBACK;
