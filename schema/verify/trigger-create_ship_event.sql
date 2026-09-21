-- Verify trigger-create_ship_event

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'create_ship_event';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'create_ship_event';

ROLLBACK;
