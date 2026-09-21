-- Verify rls-policies

BEGIN;

SELECT 1/(CASE WHEN count(*) = 8 THEN 1 ELSE 0 END) FROM pg_tables
 WHERE schemaname = 'public' AND rowsecurity
   AND tablename IN ('player','ship','ship_control','fleet','event','planet','variable','ship_flight_recorder');
SELECT 1/count(*) FROM pg_policies WHERE tablename = 'ship' AND policyname = 'ship_own_select';
SELECT 1/(CASE WHEN has_column_privilege('players', 'planet', 'fuel', 'SELECT') THEN 0 ELSE 1 END);
SELECT 1/(CASE WHEN has_column_privilege('players', 'planet', 'name', 'SELECT') THEN 1 ELSE 0 END);

ROLLBACK;
