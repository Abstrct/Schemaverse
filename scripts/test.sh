#!/usr/bin/env bash
# Run the pgTAP suite in tests/ against the running docker stack.
# Each file opens a transaction and rolls it back, so the game state is untouched.
set -uo pipefail
cd "$(dirname "$0")/.."
COMPOSE="docker compose -f docker/compose.yml"
fail=0
for t in tests/[0-9]*.sql; do
  printf '\n### %s\n' "$t"
  out=$( { cat tests/_prelude.sql; sed '1{/_prelude/d;}' "$t"; } | $COMPOSE exec -T db psql -U postgres -d schemaverse -qtA 2>&1 )
  rc=$?
  echo "$out"
  if [[ $rc -ne 0 ]] || grep -qE '^not ok|^# Looks like|^ERROR' <<<"$out"; then
    echo ">>> FAILED: $t"; fail=1
  fi
done
[[ $fail -eq 0 ]] && printf '\nALL TESTS PASSED\n'
exit $fail
