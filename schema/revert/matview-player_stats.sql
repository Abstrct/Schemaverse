-- Revert matview-player_stats

BEGIN;

DROP MATERIALIZED VIEW player_stats;

COMMIT;
