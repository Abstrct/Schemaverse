-- Verify trigger-trophy_script_update@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'trophy_script_update';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'trophy_script_update';

ROLLBACK;
