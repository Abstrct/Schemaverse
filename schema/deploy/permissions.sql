-- Deploy permissions

BEGIN;


REVOKE SELECT ON pg_proc FROM public;
REVOKE SELECT ON pg_proc FROM players;
REVOKE create ON schema public FROM public; 
REVOKE create ON schema public FROM players;

REVOKE ALL ON tic_seq FROM players;
GRANT SELECT ON tic_seq TO players;

REVOKE ALL ON round_seq FROM players;
GRANT SELECT ON round_seq TO players;

REVOKE ALL ON variable FROM players;
GRANT SELECT ON public_variable TO players;
GRANT INSERT ON public_variable TO players;
GRANT UPDATE ON public_variable TO players;
GRANT DELETE ON public_variable TO players;


REVOKE ALL ON player FROM players;
REVOKE ALL ON player_id_seq FROM players;
GRANT SELECT ON my_player TO players;
GRANT UPDATE ON my_player TO players;
GRANT SELECT ON online_players TO players;

REVOKE ALL ON ship_control FROM players;
REVOKE ALL ON ship_flight_recorder FROM players;
GRANT UPDATE ON my_ships TO players;
GRANT SELECT ON my_ships TO players;
GRANT INSERT ON my_ships TO players;
GRANT SELECT ON ships_in_range TO players;
GRANT SELECT ON my_ships_flight_recorder TO players;

REVOKE ALL ON ship FROM players;
REVOKE ALL ON ship_id_seq FROM players;


REVOKE ALL ON planet FROM players;
REVOKE ALL ON planet_id_seq FROM players;
REVOKE ALL ON planet_miners FROM players;
GRANT SELECT ON planets TO players;
GRANT UPDATE ON planets TO players;

REVOKE ALL ON event FROM players;
GRANT SELECT ON my_events TO players;

REVOKE ALL ON fleet FROM players;
REVOKE ALL ON fleet_id_seq FROM players;
GRANT INSERT ON my_fleets TO players;
GRANT SELECT ON my_fleets TO players;
GRANT UPDATE ON my_fleets TO players; 

REVOKE ALL ON price_list FROM players;
GRANT SELECT ON price_list TO players;


REVOKE ALL ON round_stats FROM players;
REVOKE ALL ON player_round_stats FROM players;
REVOKE ALL ON player_overall_stats FROM players;
REVOKE ALL ON current_stats FROM players;
REVOKE ALL ON current_player_stats FROM players;
REVOKE ALL ON current_round_stats FROM players;
GRANT SELECT ON round_stats TO players;
GRANT SELECT ON player_round_stats TO players;
GRANT SELECT ON player_overall_stats TO players;
GRANT SELECT ON current_stats TO players;
GRANT SELECT ON current_player_stats TO players;
GRANT SELECT ON current_round_stats TO players;


REVOKE ALL ON action FROM players;
GRANT SELECT ON action TO players;
GRANT INSERT ON action TO players;
GRANT UPDATE ON action TO players;

REVOKE ALL ON trophy FROM players;
GRANT SELECT ON trophy TO players;
GRANT INSERT ON trophy TO players;
GRANT UPDATE ON trophy TO players;

REVOKE ALL ON player_trophy FROM players;
GRANT SELECT ON player_trophy TO players;

REVOKE ALL ON trophy_case FROM players;
GRANT SELECT ON trophy_case TO players;

COMMIT;
