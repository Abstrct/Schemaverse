-- Verify table-price_list

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'price_list';

ROLLBACK;
