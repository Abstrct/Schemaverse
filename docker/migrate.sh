#!/bin/sh
# Deploy the schema, then give the web interface's two service roles their
# passwords: registrar (may only call register_player) and spectator (read-only,
# behind the public profile, fleet and replay pages). Runs in the sqitch image,
# which has psql.
set -e
sqitch deploy --verify
if [ -n "$REGISTRAR_PASSWORD" ]; then
  psql -h "${PGHOST:-db}" -U schemaverse -d schemaverse -v ON_ERROR_STOP=1 -q -v p="$REGISTRAR_PASSWORD" <<'SQL'
ALTER ROLE registrar PASSWORD :'p';
SQL
  echo "registrar password set"
fi
if [ -n "$SPECTATOR_PASSWORD" ]; then
  psql -h "${PGHOST:-db}" -U schemaverse -d schemaverse -v ON_ERROR_STOP=1 -q -v p="$SPECTATOR_PASSWORD" <<'SQL'
ALTER ROLE spectator PASSWORD :'p';
SQL
  echo "spectator password set"
fi
