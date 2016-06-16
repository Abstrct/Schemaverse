-- Revert data-schemaverse_player

BEGIN;

DELETE FROM player WHERE id=0;

COMMIT;
