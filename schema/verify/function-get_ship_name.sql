-- Verify function-get_ship_name

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_ship_name';

ROLLBACK;
