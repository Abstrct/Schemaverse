-- Verify trigger-update_planet

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'update_planet';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'update_planet';

ROLLBACK;
