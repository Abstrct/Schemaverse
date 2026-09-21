-- Verify trigger-destroy_ship@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'destroy_ship';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'destroy_ship';

ROLLBACK;
