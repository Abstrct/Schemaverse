-- Verify trigger-destroy_ship
-- The reworked function must not mention the dropped cache tables, and the trigger must still be attached.

BEGIN;

SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'destroy_ship' AND tgrelid = 'ship'::regclass;

SELECT 1/(CASE WHEN prosrc ~* 'ships_near_' THEN 0 ELSE 1 END)
  FROM pg_proc WHERE proname = 'destroy_ship';

ROLLBACK;
