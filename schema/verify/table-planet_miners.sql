-- Verify table-planet_miners

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'planet_miners';

ROLLBACK;
