-- Verify function-attack

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'GRACE_TICS' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'attack';

ROLLBACK;
