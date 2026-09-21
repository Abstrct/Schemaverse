#!/bin/sh
# Deploy the schema, then give the registrar role its password so the web
# interface can register players. Runs in the sqitch image, which has psql.
set -e
sqitch deploy --verify
if [ -n "$REGISTRAR_PASSWORD" ]; then
  psql -h "${PGHOST:-db}" -U schemaverse -d schemaverse -v ON_ERROR_STOP=1 -q -v p="$REGISTRAR_PASSWORD" <<'SQL'
ALTER ROLE registrar PASSWORD :'p';
SQL
  echo "registrar password set"
fi
