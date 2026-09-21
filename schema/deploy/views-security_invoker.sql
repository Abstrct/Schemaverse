-- Deploy views-security_invoker
-- requires: rls-policies
--
-- With row level security on the tables, the my_* views no longer need to run
-- as the owner. security_invoker makes them plain SQL over RLS-protected
-- tables: the same rows, but the policy is enforced by the table, and a player
-- who reads the view definition (\d+ my_ships) sees the whole truth.
--
-- Views that must see other players' data (ships_in_range, planets_in_range,
-- online_players, the stats views, trophy_case) stay owner-run.

BEGIN;

ALTER VIEW my_player SET (security_invoker = true);
ALTER VIEW my_ships SET (security_invoker = true);
ALTER VIEW my_fleets SET (security_invoker = true);
ALTER VIEW my_events SET (security_invoker = true);
ALTER VIEW public_variable SET (security_invoker = true);
ALTER VIEW planets SET (security_invoker = true);
ALTER VIEW my_ships_flight_recorder SET (security_invoker = true);

COMMIT;
