-- Verify function-get_player_error_channel

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'get_player_error_channel';

ROLLBACK;
