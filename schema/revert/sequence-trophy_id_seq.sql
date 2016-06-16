-- Revert sequence-trophy_id_seq

BEGIN;

DROP SEQUENCE trophy_id_seq;

COMMIT;
