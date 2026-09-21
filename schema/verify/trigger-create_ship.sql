-- Verify trigger-create_ship

BEGIN;

SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'create_ship' AND tgrelid = 'ship'::regclass;
SELECT 1/(CASE WHEN prosrc ~ 'MAX_SHIPS' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'create_ship';

ROLLBACK;
