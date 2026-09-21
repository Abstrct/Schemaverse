-- Verify function-map_snapshot

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'map_snapshot' AND NOT prosecdef;
SELECT 1/(CASE WHEN has_function_privilege('players', 'map_snapshot()', 'EXECUTE') THEN 1 ELSE 0 END);

ROLLBACK;
