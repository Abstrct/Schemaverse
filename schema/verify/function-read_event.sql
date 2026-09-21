-- Verify function-read_event

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'read_event';

ROLLBACK;
