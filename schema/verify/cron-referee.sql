-- Verify cron-referee

BEGIN;

SELECT 1/count(*) FROM cron.job WHERE jobname = 'referee' AND active;

ROLLBACK;
