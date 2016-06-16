-- Revert sequence-event_id_seq

BEGIN;

DROP SEQUENCE event_id_seq;

COMMIT;
