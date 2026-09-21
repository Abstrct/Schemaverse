-- Verify trigger-player_creation

BEGIN;

SELECT 1/(CASE WHEN prosrc ~ 'SPAWN_MIN_DISTANCE' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'player_creation';

ROLLBACK;
