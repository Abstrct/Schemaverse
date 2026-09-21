-- Verify sequence-trophy_id_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'trophy_id_seq';

ROLLBACK;
