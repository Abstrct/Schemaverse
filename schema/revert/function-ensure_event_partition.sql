-- Revert function-ensure_event_partition

BEGIN;

DROP FUNCTION ensure_event_partition(integer);

COMMIT;
