-- Revert sequence-fleet_id_seq

BEGIN;

DROP SEQUENCE fleet_id_seq;

COMMIT;
