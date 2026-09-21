-- Verify function-register_player

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'LATE_JOIN_STIPEND' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'register_player';

ROLLBACK;
