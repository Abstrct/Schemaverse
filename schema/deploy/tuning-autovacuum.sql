-- Deploy tuning-autovacuum
-- requires: table-ship
-- requires: table-event
--
-- tic.pl ran CLUSTER and VACUUM on ship every tic under an exclusive lock.
-- Autovacuum with per-table thresholds does the job without blocking anyone.

BEGIN;

ALTER TABLE ship SET (
	autovacuum_vacuum_scale_factor = 0.02,
	autovacuum_analyze_scale_factor = 0.02,
	autovacuum_vacuum_cost_delay = 0
);
ALTER TABLE ship_control SET (
	autovacuum_vacuum_scale_factor = 0.02,
	autovacuum_analyze_scale_factor = 0.02,
	autovacuum_vacuum_cost_delay = 0
);
ALTER TABLE event SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.05
);
ALTER TABLE ship_flight_recorder SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.05
);
ALTER TABLE planet_miners SET (
	autovacuum_vacuum_scale_factor = 0.1,
	autovacuum_vacuum_cost_delay = 0
);
ALTER TABLE planet SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.05
);
ALTER TABLE player SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.05
);

COMMIT;
