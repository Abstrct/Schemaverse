-- Deploy matview-player_stats
-- requires: view-current_player_stats
--
-- current_player_stats aggregates the whole event table per call. stat.pl used
-- to copy it into player_round_stats one player at a time in a busy loop.
-- A materialized view refreshed by the tic gives everyone a cheap, consistent
-- snapshot; the refreshed column says how old it is.

BEGIN;

CREATE MATERIALIZED VIEW player_stats AS
	SELECT s.*, now() AS refreshed FROM current_player_stats s;

CREATE UNIQUE INDEX player_stats_player_id_idx ON player_stats (player_id);

GRANT SELECT ON player_stats TO players;

COMMIT;
