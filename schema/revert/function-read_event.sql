-- Revert function-read_event

BEGIN;

DROP FUNCTION read_event(integer);

COMMIT;
