-- Deploy role-spectator
-- requires: fleet-shared
-- requires: view-trophy_case
-- requires: matview-player_stats
-- requires: event-partitioned
-- requires: rls-policies
-- requires: view-online_players
-- requires: view-current_stats
-- requires: view-planets
--
-- The public face of the game: player profiles with their trophy cases,
-- shared fleet scripts and round replays, served by the web interface to
-- anyone, no login. The spectator role can read only what every player can
-- already see about everyone else, and nothing a player can see only about
-- themselves. The web tier keeps its rule, a browser has the powers of one
-- psql session; for a visitor that session is spectator. Its password is set
-- by docker/migrate.sh from SPECTATOR_PASSWORD, and register_player() refuses
-- the name because it is a role.

BEGIN;

CREATE ROLE spectator WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;

-- Who plays: the columns player_badge() already gives away, plus when they joined.
CREATE VIEW player_profile AS
	SELECT id, username, created, symbol, rgb FROM player;
COMMENT ON VIEW player_profile IS 'The public identity of every player.';
GRANT SELECT ON player_profile TO players, spectator;

-- Planets. The planets view is security_invoker, so the policy lives on the table.
CREATE POLICY planet_spectator_select ON planet FOR SELECT TO spectator USING (true);
GRANT SELECT (id, name, mine_limit, location_x, location_y, conqueror_id, location) ON planet TO spectator;
GRANT SELECT ON planets TO spectator;

-- Events: the public ones only, this round and every round before it.
CREATE POLICY event_spectator_select ON event FOR SELECT TO spectator USING (public);
GRANT SELECT ON event, event_archive, my_events, action TO spectator;

-- Standings, trophies, shared scripts, and the clock.
GRANT SELECT ON trophy, player_trophy, trophy_case, player_stats, player_round_stats, player_overall_stats,
	round_stats, current_stats, online_players, shared_fleets TO spectator;
GRANT SELECT ON tic_seq, round_seq TO spectator;

COMMIT;
