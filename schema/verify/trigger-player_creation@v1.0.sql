-- Verify trigger-player_creation@v1.0

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'player_creation';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'player_creation';

ROLLBACK;
