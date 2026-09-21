-- Verify sequence-event_id_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'event_id_seq';

ROLLBACK;
