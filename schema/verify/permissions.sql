-- Verify permissions

BEGIN;

SELECT 1/(CASE WHEN has_table_privilege('players', 'my_ships', 'SELECT') AND NOT has_table_privilege('players', 'ship', 'SELECT') THEN 1 ELSE 0 END);

ROLLBACK;
