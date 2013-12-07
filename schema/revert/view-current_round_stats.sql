-- Revert view-current_round_stats

BEGIN;

DROP VIEW current_round_stats;

COMMIT;
