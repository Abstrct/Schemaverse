-- Verify function-set_numeric_variable

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'set_numeric_variable';

ROLLBACK;
