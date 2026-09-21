-- Verify permissions-my_ships_delete

BEGIN;

SELECT 1/(CASE WHEN has_table_privilege('players', 'my_ships', 'DELETE') THEN 1 ELSE 0 END);

ROLLBACK;
