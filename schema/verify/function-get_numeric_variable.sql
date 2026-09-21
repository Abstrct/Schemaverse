-- Verify function-get_numeric_variable

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_numeric_variable';

ROLLBACK;
