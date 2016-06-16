-- Revert view-my_player

BEGIN;

DROP RULE my_player_starting_fleet ON my_player;

DROP VIEW my_player;

COMMIT;
