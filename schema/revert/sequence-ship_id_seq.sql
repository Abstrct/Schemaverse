-- Revert sequence-ship_id_seq

BEGIN;

DROP SEQUENCE ship_id_seq;

COMMIT;
