-- Verify indexes

BEGIN;

SELECT 1/count(*) FROM pg_indexes WHERE indexname = 'ship_location_index';

ROLLBACK;
