-- Verify matview-player_stats

BEGIN;

SELECT 1/count(*) FROM pg_matviews WHERE matviewname = 'player_stats';
SELECT 1/(CASE WHEN has_table_privilege('players', 'player_stats', 'SELECT') THEN 1 ELSE 0 END);

ROLLBACK;
