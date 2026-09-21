-- Verify function-current_round

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'current_round';
SELECT 1/(CASE WHEN current_round() >= 1 THEN 1 ELSE 0 END);

ROLLBACK;
