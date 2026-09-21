-- Revert role-spectator

BEGIN;

DROP POLICY event_spectator_select ON event;
DROP POLICY planet_spectator_select ON planet;
DROP VIEW player_profile;
REVOKE ALL ON planet, planets, event, event_archive, my_events, action,
	trophy, player_trophy, trophy_case, player_stats, player_round_stats, player_overall_stats,
	round_stats, current_stats, online_players, shared_fleets FROM spectator;
REVOKE ALL ON tic_seq, round_seq FROM spectator;
DROP ROLE spectator;

COMMIT;
