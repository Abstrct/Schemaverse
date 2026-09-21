-- Verify function-current_tic

BEGIN;

SELECT 1/(CASE WHEN current_tic() >= 1 THEN 1 ELSE 0 END);

ROLLBACK;
