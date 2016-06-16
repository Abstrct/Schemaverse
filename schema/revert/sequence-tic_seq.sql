-- Revert sequence-tic_seq

BEGIN;

DROP SEQUENCE tic_seq;

COMMIT;
