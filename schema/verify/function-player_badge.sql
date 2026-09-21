-- Verify function-player_badge

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'player_badge' AND prosecdef;
SELECT 1/(CASE WHEN player_badge(0)->>'username' = 'schemaverse' THEN 1 ELSE 0 END);

ROLLBACK;
