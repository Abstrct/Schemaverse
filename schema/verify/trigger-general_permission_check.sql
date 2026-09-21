-- Verify trigger-general_permission_check

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'general_permission_check';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'a_ship_permission_check';

ROLLBACK;
