-- Verify table-player_trophy

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'player_trophy';

ROLLBACK;
