-- Verify function-action_permission_check

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'action_permission_check';

ROLLBACK;
