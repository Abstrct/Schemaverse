-- Verify sequence-tic_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'tic_seq';

ROLLBACK;
