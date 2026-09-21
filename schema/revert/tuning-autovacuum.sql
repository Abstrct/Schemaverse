-- Revert tuning-autovacuum

BEGIN;

ALTER TABLE ship RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor, autovacuum_vacuum_cost_delay);
ALTER TABLE ship_control RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor, autovacuum_vacuum_cost_delay);
DO $$ BEGIN
	IF (SELECT relkind FROM pg_class WHERE relname = 'event') = 'r' THEN
		ALTER TABLE event RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor);
	END IF;
END $$;
ALTER TABLE ship_flight_recorder RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor);
ALTER TABLE planet_miners RESET (autovacuum_vacuum_scale_factor, autovacuum_vacuum_cost_delay);
ALTER TABLE planet RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor);
ALTER TABLE player RESET (autovacuum_vacuum_scale_factor, autovacuum_analyze_scale_factor);

COMMIT;
