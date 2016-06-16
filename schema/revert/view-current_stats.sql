-- Revert view-current_stats

BEGIN;

DROP VIEW current_stats;

COMMIT;
