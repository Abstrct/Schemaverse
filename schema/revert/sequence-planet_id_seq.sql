-- Revert sequence-planet_id_seq

BEGIN;

DROP SEQUENCE planet_id_seq;

COMMIT;
