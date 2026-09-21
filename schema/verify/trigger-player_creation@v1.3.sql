-- Verify trigger-player_creation

BEGIN;

SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'player_creation' AND tgrelid = 'player'::regclass;
SELECT 1/(CASE WHEN prosrc !~* 'CREATE ROLE' THEN 1 ELSE 0 END) FROM pg_proc WHERE proname = 'player_creation';

ROLLBACK;
