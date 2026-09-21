-- Revert player-joined_tic

BEGIN;

ALTER TABLE player DROP COLUMN joined_tic;

COMMIT;
