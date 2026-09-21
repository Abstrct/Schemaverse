-- Verify data-missions

BEGIN;

SELECT 1/(CASE WHEN count(*) >= 11 THEN 1 ELSE 0 END) FROM mission;

ROLLBACK;
