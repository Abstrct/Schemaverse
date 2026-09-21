-- Verify function-generate_string

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'generate_string';

ROLLBACK;
