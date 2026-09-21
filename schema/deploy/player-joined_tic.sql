-- Deploy player-joined_tic
-- requires: table-player
-- requires: function-current_tic
--
-- The tic a player joined the current round. register_player() stamps it and
-- round_control() resets it to 0 for everyone, so a round start counts as a
-- fresh join. The GRACE_TICS lever reads it.

BEGIN;

ALTER TABLE player ADD COLUMN joined_tic integer NOT NULL DEFAULT 0;
GRANT SELECT (joined_tic) ON player TO players;

COMMIT;
