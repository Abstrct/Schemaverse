-- Verify trigger-create_trophy

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'create_trophy';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'create_trophy';

ROLLBACK;
