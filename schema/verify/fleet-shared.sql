-- Verify fleet-shared

BEGIN;

SELECT 1/count(*) FROM information_schema.columns WHERE table_name = 'fleet' AND column_name = 'shared';
SELECT 1/count(*) FROM information_schema.columns WHERE table_name = 'my_fleets' AND column_name = 'shared';
SELECT 1/count(*) FROM pg_views WHERE viewname = 'shared_fleets';
SELECT 1/count(*) FROM pg_trigger WHERE tgname = 'fleet_share_stamp';
SELECT 1/(CASE WHEN has_column_privilege('players', 'fleet', 'shared', 'UPDATE') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_table_privilege('players', 'shared_fleets', 'SELECT') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_table_privilege('players', 'my_fleets', 'UPDATE') THEN 1 ELSE 0 END);

ROLLBACK;
