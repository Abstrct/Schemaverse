-- Verify function-convert_resource

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'convert_resource';

ROLLBACK;
