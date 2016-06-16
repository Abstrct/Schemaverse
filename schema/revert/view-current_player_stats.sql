-- Revert view-current_player_stats

BEGIN;

DROP VIEW current_player_stats;

COMMIT;
