-- Revert sequence-round_seq

BEGIN;

DROP SEQUENCE round_seq;

COMMIT;
