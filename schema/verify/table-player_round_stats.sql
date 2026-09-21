-- Verify table-player_round_stats

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'player_round_stats';

ROLLBACK;
