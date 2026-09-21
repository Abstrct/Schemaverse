-- Verify role-spectator

BEGIN;

SELECT 1/count(*) FROM pg_roles WHERE rolname = 'spectator' AND rolcanlogin AND NOT rolsuper AND NOT rolcreaterole;
SELECT 1/(CASE WHEN pg_has_role('spectator', 'players', 'MEMBER') THEN 0 ELSE 1 END);
SELECT 1/count(*) FROM pg_views WHERE viewname = 'player_profile';
SELECT 1/count(*) FROM pg_policies WHERE tablename = 'event' AND policyname = 'event_spectator_select';
SELECT 1/count(*) FROM pg_policies WHERE tablename = 'planet' AND policyname = 'planet_spectator_select';
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'trophy_case', 'SELECT') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'shared_fleets', 'SELECT') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'player_stats', 'SELECT') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'fleet', 'SELECT') THEN 0 ELSE 1 END);
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'ship', 'SELECT') THEN 0 ELSE 1 END);
SELECT 1/(CASE WHEN has_table_privilege('spectator', 'player', 'SELECT') THEN 0 ELSE 1 END);
SELECT 1/(CASE WHEN has_column_privilege('spectator', 'planet', 'fuel', 'SELECT') THEN 0 ELSE 1 END);
SELECT 1/(CASE WHEN has_function_privilege('spectator', 'register_player(text,text)', 'EXECUTE') THEN 0 ELSE 1 END);

ROLLBACK;
