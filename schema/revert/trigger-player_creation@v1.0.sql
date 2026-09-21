-- Revert trigger-player_creation

BEGIN;

DROP TRIGGER player_creation ON player;

DROP FUNCTION player_creation();

COMMIT;
