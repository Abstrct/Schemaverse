-- Verify sequence-planet_id_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'planet_id_seq';

ROLLBACK;
