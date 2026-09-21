-- Verify sequence-ship_id_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'ship_id_seq';

ROLLBACK;
