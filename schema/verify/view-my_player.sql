-- Verify view-my_player

BEGIN;

SELECT 1/count(*) FROM pg_views WHERE viewname = 'my_player';
SELECT 1/(CASE WHEN count(*) = 0 THEN 1 ELSE 0 END) FROM information_schema.columns WHERE table_name = 'my_player' AND column_name = 'password';
SELECT 1/(CASE WHEN has_table_privilege('players', 'my_player', 'UPDATE') THEN 1 ELSE 0 END);

ROLLBACK;
