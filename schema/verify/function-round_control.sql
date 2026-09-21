-- Verify function-round_control

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'joined_tic' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'round_control';

ROLLBACK;
