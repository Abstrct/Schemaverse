-- Verify procedure-tic

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'ensure_event_partition' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'tic_open';

ROLLBACK;
