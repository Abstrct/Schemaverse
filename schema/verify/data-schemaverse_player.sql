-- Verify data-schemaverse_player

BEGIN;

SELECT 1/count(*) FROM player WHERE id = 0 AND username = 'schemaverse';

ROLLBACK;
