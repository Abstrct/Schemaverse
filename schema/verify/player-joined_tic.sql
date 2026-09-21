-- Verify player-joined_tic

BEGIN;

SELECT 1/count(*) FROM information_schema.columns WHERE table_name = 'player' AND column_name = 'joined_tic';

ROLLBACK;
