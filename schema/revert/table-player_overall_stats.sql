-- Revert table-player_overall_stats

BEGIN;

DROP TABLE player_overall_stats;

COMMIT;
