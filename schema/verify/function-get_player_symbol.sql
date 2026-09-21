-- Verify function-get_player_symbol

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_player_symbol';

ROLLBACK;
