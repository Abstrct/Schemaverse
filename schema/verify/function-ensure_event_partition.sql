-- Verify function-ensure_event_partition

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'ensure_event_partition';

ROLLBACK;
