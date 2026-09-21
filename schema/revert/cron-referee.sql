-- Revert cron-referee

BEGIN;

SELECT cron.unschedule('referee');

COMMIT;
