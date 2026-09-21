-- Verify function-round_control@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'round_control';

ROLLBACK;
