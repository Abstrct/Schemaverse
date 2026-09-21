-- Verify function-upgrade

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'UPGRADE_PRICE_SCALE' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'upgrade';

ROLLBACK;
