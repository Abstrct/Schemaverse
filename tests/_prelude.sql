-- Included at the top of every test via \i. Opens a transaction that the test
-- rolls back, and lets player roles created inside the test write pgTAP's
-- per-session temp tables after SET SESSION AUTHORIZATION.
\set ON_ERROR_STOP 1
\set QUIET 1
BEGIN;
-- The runner connects as the postgres superuser so that SET SESSION
-- AUTHORIZATION works; everything a test does happens as the game owner or a
-- player it registers.
SET SESSION AUTHORIZATION schemaverse;
-- The session's temp schema only exists once something has been created in it.
CREATE TEMP TABLE _prelude_probe (x int) ON COMMIT DROP;
SELECT nspname AS tmpns FROM pg_namespace WHERE oid = pg_my_temp_schema() \gset
