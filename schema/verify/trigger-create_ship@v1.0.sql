-- Verify trigger-create_ship@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'create_ship';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'create_ship';

ROLLBACK;
