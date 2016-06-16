-- Revert sequence-player_id_seq

BEGIN;

DROP SEQUENCE player_id_seq;

COMMIT;
