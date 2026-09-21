-- Verify function-set_char_variable

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'set_char_variable';

ROLLBACK;
