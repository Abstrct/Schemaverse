-- Verify procedure-tic

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'tic_economy';
SELECT 1/(CASE WHEN prosrc ~ 'check_all_missions' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'tic_close';

ROLLBACK;
