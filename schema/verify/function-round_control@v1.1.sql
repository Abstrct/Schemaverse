-- Verify function-round_control

BEGIN;

SELECT 1/(CASE WHEN prosrc !~* 'COPY tmp_current_round_archive' AND prosrc !~* 'disable trigger all' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'round_control';

ROLLBACK;
