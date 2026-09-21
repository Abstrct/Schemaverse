-- Verify views-security_invoker

BEGIN;

SELECT 1/(CASE WHEN count(*) = 7 THEN 1 ELSE 0 END) FROM pg_class
 WHERE relkind = 'v' AND 'security_invoker=true' = ANY(reloptions)
   AND relname IN ('my_player','my_ships','my_fleets','my_events','public_variable','planets','my_ships_flight_recorder');

ROLLBACK;
