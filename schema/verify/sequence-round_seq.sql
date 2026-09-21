-- Verify sequence-round_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'round_seq';

ROLLBACK;
