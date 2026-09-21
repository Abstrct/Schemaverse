-- Verify view-my_ships_flight_recorder

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE schemaname = 'public' AND viewname = 'my_ships_flight_recorder';

ROLLBACK;
