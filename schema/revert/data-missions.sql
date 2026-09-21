-- Revert data-missions

BEGIN;

DELETE FROM mission_progress;
DELETE FROM mission;

COMMIT;
