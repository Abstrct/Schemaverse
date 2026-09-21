-- Revert function-map_snapshot

BEGIN;

DROP FUNCTION map_snapshot();

COMMIT;
