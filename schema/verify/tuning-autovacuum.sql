-- Verify tuning-autovacuum

BEGIN;

SELECT 1/count(*) FROM pg_class WHERE relname = 'ship' AND 'autovacuum_vacuum_scale_factor=0.02' = ANY(reloptions);

ROLLBACK;
