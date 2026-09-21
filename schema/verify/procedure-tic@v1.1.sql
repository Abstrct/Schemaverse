-- Verify procedure-tic

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'tic_open' AND prokind = 'p';
SELECT 1/count(*) FROM pg_proc WHERE proname = 'tic_close' AND prokind = 'p';
SELECT 1/count(*) FROM pg_proc WHERE proname = 'tic_health';
SELECT 1/(CASE WHEN has_function_privilege('players', 'tic_health(integer)', 'EXECUTE') THEN 0 ELSE 1 END);

ROLLBACK;
