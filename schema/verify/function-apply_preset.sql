-- Verify function-apply_preset

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'apply_preset';

ROLLBACK;
