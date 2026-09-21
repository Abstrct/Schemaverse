-- Verify function-attack

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'attack';

ROLLBACK;
