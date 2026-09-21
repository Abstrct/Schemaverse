-- Revert function-player_badge

BEGIN;

DROP FUNCTION player_badge(integer);

COMMIT;
