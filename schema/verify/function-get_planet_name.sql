-- Verify function-get_planet_name

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_planet_name';

ROLLBACK;
