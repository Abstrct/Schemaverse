-- Verify function-get_player_id

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_player_id';

ROLLBACK;
