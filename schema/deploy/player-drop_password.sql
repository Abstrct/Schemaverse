-- Deploy player-drop_password
-- requires: view-my_player

BEGIN;

ALTER TABLE player DROP COLUMN password;

COMMIT;
