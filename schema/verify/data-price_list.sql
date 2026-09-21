-- Verify data-price_list

BEGIN;

SELECT 1/count(*) FROM price_list WHERE code = 'SHIP';

ROLLBACK;
