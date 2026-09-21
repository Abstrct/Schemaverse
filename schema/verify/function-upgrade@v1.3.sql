-- Verify function-upgrade

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'only upgrade your own ships' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'upgrade';

ROLLBACK;
