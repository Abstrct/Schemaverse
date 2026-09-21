-- Verify trigger-id_dealer

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'id_dealer';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'ship_id_dealer';

ROLLBACK;
