-- Revert player-drop_password

BEGIN;

ALTER TABLE player ADD COLUMN password character(40);

COMMIT;
