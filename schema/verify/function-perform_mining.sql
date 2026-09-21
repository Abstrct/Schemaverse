-- Verify function-perform_mining

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'perform_mining';

ROLLBACK;
