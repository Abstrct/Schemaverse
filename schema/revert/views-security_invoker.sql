-- Revert views-security_invoker

BEGIN;

ALTER VIEW my_player SET (security_invoker = false);
ALTER VIEW my_ships SET (security_invoker = false);
ALTER VIEW my_fleets SET (security_invoker = false);
ALTER VIEW my_events SET (security_invoker = false);
ALTER VIEW public_variable SET (security_invoker = false);
ALTER VIEW planets SET (security_invoker = false);
ALTER VIEW my_ships_flight_recorder SET (security_invoker = false);

COMMIT;
