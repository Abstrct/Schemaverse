-- Verify table-ship_flight_recorder

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ship_flight_recorder';

ROLLBACK;
