-- Verify function-get_char_variable

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_char_variable';

ROLLBACK;
