#!/usr/bin/env bash
# Create a player. Usage: scripts/new_player.sh <username> <password>
# Calls register_player() inside the db container. It creates the PostgreSQL
# role (server-side password hashing) and the player row; the player_creation
# trigger then assigns a home planet.
set -euo pipefail
name="${1:-}"; pass="${2:-}"
if [[ -z "$name" || -z "$pass" ]]; then
  echo "usage: $0 <username> <password>" >&2; exit 2
fi
cd "$(dirname "$0")/.."
docker compose -f docker/compose.yml exec -T db \
  psql -U schemaverse -d schemaverse -v ON_ERROR_STOP=1 -qtA \
       -v name="$name" -v pass="$pass" <<'SQL' >/dev/null
SELECT register_player(:'name', :'pass');
SQL
echo "player '$name' created. Connect with: psql -h localhost -U $name schemaverse"
