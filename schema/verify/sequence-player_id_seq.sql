-- Verify sequence-player_id_seq

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' AND relname = 'player_id_seq';

ROLLBACK;
