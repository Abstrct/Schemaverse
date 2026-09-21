-- Verify function-round_control

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'ON CONFLICT DO NOTHING' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'round_control';

ROLLBACK;
