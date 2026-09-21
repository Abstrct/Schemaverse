-- Verify function-disable_fleet

BEGIN;

SELECT 1/(CASE WHEN prosecdef THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'disable_fleet';

ROLLBACK;
