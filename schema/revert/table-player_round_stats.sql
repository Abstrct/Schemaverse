-- Revert view-player_round_stats

BEGIN;

DROP TABLE player_round_stats;

COMMIT;
