-- Verify trigger-variable_insert

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'variable_insert';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'variable_insert';

ROLLBACK;
