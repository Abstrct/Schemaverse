#!/usr/bin/env bash
# First-boot setup, run by the image as the postgres superuser.
#
# The game owner "schemaverse" is deliberately NOT a superuser. It owns the
# database and every object in it, can create player roles, and gets exactly
# two extra powers: cancelling other sessions' queries (the referee) and
# reading their query text in pg_stat_activity. Everything else the schema
# needs works with ownership alone.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
	CREATE ROLE schemaverse WITH LOGIN NOSUPERUSER CREATEROLE NOCREATEDB NOREPLICATION
		PASSWORD '${SCHEMAVERSE_PASSWORD}';
	GRANT pg_signal_backend, pg_read_all_stats TO schemaverse;
	CREATE DATABASE schemaverse OWNER schemaverse;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname schemaverse <<-EOSQL
	CREATE EXTENSION IF NOT EXISTS pgtap;
	CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
	CREATE EXTENSION IF NOT EXISTS pg_cron;
	GRANT USAGE ON SCHEMA cron TO schemaverse;
EOSQL
