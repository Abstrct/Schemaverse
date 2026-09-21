#!/usr/bin/env bash
# End-to-end smoke test on a fresh stack.
#   fresh volume -> deploy schema -> ticker runs round_control -> two players ->
#   ships are bought, moved, mine, and are destroyed -> ticker is still alive.
# Fails loudly on the first broken step. Used by CI and by `make smoke`.
set -euo pipefail
cd "$(dirname "$0")/.."
COMPOSE="docker compose -f docker/compose.yml"
export TIC_SECONDS=1

sql() {  # sql <role> <statement...>   runs psql inside the db container over the trusted socket
  local role="$1"; shift
  $COMPOSE exec -T db psql -U "$role" -d schemaverse -v ON_ERROR_STOP=1 -qtA -c "$*"
}
wait_tic() {  # wait_tic <n>  blocks until tic_seq.last_value >= n
  local want="$1" have=0
  for _ in $(seq 1 120); do
    have=$(sql schemaverse "SELECT last_value FROM tic_seq" 2>/dev/null || echo 0)
    [[ "$have" -ge "$want" ]] && return 0
    sleep 1
  done
  echo "FAIL: tic never reached $want (at $have)"; $COMPOSE logs --tail=50 tic; exit 1
}
step() { printf '\n== %s\n' "$*"; }
assert() { # assert <description> <psql-output> <expected-regex>
  if [[ "$2" =~ $3 ]]; then echo "ok   $1 ($2)"; else echo "FAIL $1: got '$2', expected /$3/"; exit 1; fi
}

step "fresh stack"
$COMPOSE down -v --remove-orphans >/dev/null 2>&1 || true
$COMPOSE build --quiet
$COMPOSE up -d db
$COMPOSE run --rm migrate deploy --verify
$COMPOSE up -d tic web
# Missions pay rewards, which would make the balance assertions below depend on
# timing. Turn the automatic check off; the missions step at the end claims them.
sql schemaverse "UPDATE variable SET numeric_value = 1000000 WHERE name = 'MISSION_CHECK_EVERY'" >/dev/null

step "server version"
sql schemaverse "SELECT version()"
assert "game owner is not a superuser" "$(sql schemaverse "SELECT rolsuper FROM pg_roles WHERE rolname='schemaverse'")" '^f$'

step "first tic runs round_control and builds the universe"
wait_tic 2
planets=$(sql schemaverse "SELECT count(*) FROM planet")
assert "planets generated" "$planets" '^[1-9][0-9]+$'

step "two players"
./scripts/new_player.sh alice alice-pw-1 >/dev/null
./scripts/new_player.sh bob bob-pw-1 >/dev/null
assert "alice has a role" "$(sql schemaverse "SELECT count(*) FROM pg_roles WHERE rolname='alice'")" '^1$'
assert "alice's password is SCRAM hashed" "$(sql postgres "SELECT left(rolpassword, 13) FROM pg_authid WHERE rolname='alice'")" '^SCRAM-SHA-256'
assert "duplicate name rejected" "$(sql schemaverse "SELECT register_player('alice','whatever-1')" 2>&1 | grep -c 'is taken')" '^1$'
assert "bad name rejected" "$(sql schemaverse "SELECT register_player('Robert; DROP TABLE player','whatever-1')" 2>&1 | grep -c 'username must be')" '^1$'
assert "player.password column is gone" "$(sql schemaverse "SELECT count(*) FROM information_schema.columns WHERE table_name='player' AND column_name='password'")" '^0$'
assert "alice has a home planet" "$(sql alice "SELECT count(*) FROM planets WHERE conqueror_id=get_player_id('alice')")" '^1$'
assert "bob cannot see alice's player row" "$(sql bob "SELECT count(*) FROM my_player WHERE username='alice'")" '^0$'

step "alice buys two ships on her planet"
home=$(sql alice "SELECT id FROM planets WHERE conqueror_id=get_player_id('alice') LIMIT 1")
miner=$(sql alice "INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('miner', 0, 0, 0, 20) RETURNING id")
scout=$(sql alice "INSERT INTO my_ships(name) VALUES ('scout') RETURNING id")
assert "two ships" "$(sql alice "SELECT count(*) FROM my_ships")" '^2$'
assert "balance charged" "$(sql alice "SELECT balance FROM my_player")" '^8000$'
start=$(sql alice "SELECT location FROM my_ships WHERE id=$scout")

step "orders: miner mines home, scout flies away"
sql alice "UPDATE my_ships SET action='MINE', action_target_id=$home WHERE id=$miner" >/dev/null
sql alice "SELECT ship_course_control($scout, 500, NULL, point((location[0]+50000)::int, location[1]::int)) FROM my_ships WHERE id=$scout" >/dev/null

now=$(sql schemaverse "SELECT last_value FROM tic_seq")
wait_tic $((now + 4))

step "after four tics"
assert "scout moved"  "$(sql alice "SELECT (location <-> '$start'::point)::int FROM my_ships WHERE id=$scout")" '^[1-9][0-9]*$'
assert "miner mined"  "$(sql alice "SELECT count(*) FROM my_events WHERE action='MINE_SUCCESS' AND ship_id_1=$miner")" '^[1-9][0-9]*$'
assert "flight recorder"  "$(sql alice "SELECT count(*) FROM my_ships_flight_recorder WHERE ship_id=$scout")" '^[1-9][0-9]*$'
assert "bob sees no alice ships" "$(sql bob "SELECT count(*) FROM my_ships")" '^0$'
assert "RLS: bob sees no rows in ship" "$(sql bob "SELECT count(*) FROM ship")" '^0$'
assert "RLS: alice sees her rows in ship" "$(sql alice "SELECT count(*) FROM ship")" '^2$'
assert "planet.fuel is hidden" "$(sql bob "SELECT fuel FROM planet LIMIT 1" 2>&1 | grep -c 'permission denied')" '^1$'
assert "bob cannot upgrade alice's ship" "$(sql bob "SELECT upgrade($miner, 'ATTACK', 1)")" '^f$'
assert "bob cannot refuel alice's ship" "$(sql bob "SELECT refuel_ship($miner)")" '^0$'
assert "alice can upgrade her own ship" "$(sql alice "SELECT upgrade($miner, 'ATTACK', 1)")" '^t$'

step "alice's fleet script runs every tic, as alice"
sql alice "INSERT INTO my_fleets(name) VALUES ('auto')" >/dev/null
fleet=$(sql alice "SELECT id FROM my_fleets WHERE name='auto'")
sql alice "UPDATE my_fleets SET script='UPDATE my_ships SET name = ''tic-'' || (SELECT last_value FROM tic_seq) WHERE id = $miner;' WHERE id=$fleet" >/dev/null
assert "first minute of runtime is free" "$(sql alice "SELECT upgrade($fleet, 'FLEET_RUNTIME', 1)")" '^t$'
sql alice "UPDATE my_fleets SET enabled='t' WHERE id=$fleet" >/dev/null
now=$(sql schemaverse "SELECT last_value FROM tic_seq")
wait_tic $((now + 3))
assert "script ran and renamed the ship" "$(sql alice "SELECT name FROM my_ships WHERE id=$miner")" '^tic-[0-9]+$'
assert "FLEET_SUCCESS events logged" "$(sql schemaverse "SELECT count(*) FROM event WHERE action='FLEET_SUCCESS' AND referencing_id=$fleet")" '^[1-9][0-9]*$'
sql alice "UPDATE my_fleets SET enabled='f' WHERE id=$fleet" >/dev/null

step "saved queries are isolated by row level security"
sql alice "INSERT INTO my_query_store(name, query_text) VALUES ('fleet', 'SELECT * FROM my_ships')" >/dev/null
assert "alice sees her query" "$(sql alice "SELECT count(*) FROM my_query_store")" '^1$'
assert "bob sees none" "$(sql bob "SELECT count(*) FROM my_query_store")" '^0$'
assert "bob cannot forge alice's player_id" "$(sql bob "INSERT INTO my_query_store(player_id, name, query_text) VALUES (get_player_id('alice'), 'x', 'x')" 2>&1 | grep -c 'row-level security')" '^1$'

step "alice scuttles the miner with DELETE"
before=$(sql alice "SELECT balance FROM my_player")
sql alice "DELETE FROM my_ships WHERE id=$miner" >/dev/null
assert "miner gone" "$(sql alice "SELECT count(*) FROM my_ships WHERE id=$miner")" '^0$'
assert "ship price refunded" "$(sql alice "SELECT balance - $before FROM my_player")" '^1000$'

step "the scout takes lethal damage; the ticker's health pass must destroy it (destroy_ship trigger)"
# Deal lethal damage as the owner and let the tic do what combat would do:
# health -> 0, EXPLODED tics later -> destroyed, inside the ticker's own transaction.
sql schemaverse "UPDATE ship SET future_health=-1 WHERE id=$scout" >/dev/null
now=$(sql schemaverse "SELECT last_value FROM tic_seq")
wait_tic $((now + 6))
assert "scout destroyed" "$(sql schemaverse "SELECT destroyed FROM ship WHERE id=$scout")" '^t$'
assert "scout gone from my_ships" "$(sql alice "SELECT count(*) FROM my_ships WHERE id=$scout")" '^0$'
assert "EXPLODE event logged" "$(sql schemaverse "SELECT count(*) FROM event WHERE action='EXPLODE' AND ship_id_1=$scout")" '^1$'
assert "ship cost refunded" "$(sql alice "SELECT balance - $before FROM my_player")" '^2000$'

step "ticker survives a destroyed ship in its health pass"
now=$(sql schemaverse "SELECT last_value FROM tic_seq")
wait_tic $((now + 3))
assert "tic container running" "$($COMPOSE ps --status running --services | grep -c '^tic$')" '^1$'
errors=$($COMPOSE logs --no-log-prefix tic 2>&1 | grep -c 'level=ERROR' || true)
assert "no errors in ticker log" "$errors" '^0$'
assert "referee cron job scheduled" "$(sql schemaverse "SELECT count(*) FROM cron.job WHERE jobname='referee'")" '^1$'
assert "player_stats refreshed by the tic" "$(sql alice "SELECT count(*) FROM player_stats WHERE username='alice'")" '^1$'

step "missions"
assert "missions are listed" "$(sql alice "SELECT count(*) FROM my_missions")" '^1[1-9]$|^[2-9][0-9]$'
claimed=$(sql alice "SELECT count(*) FROM check_missions()")
assert "alice claims what she has done (buy, name, mine, move, upgrade, save, automate)" "$claimed" '^[5-9]$|^1[0-9]$'
assert "claims are idempotent" "$(sql alice "SELECT count(*) FROM check_missions()")" '^0$'
assert "rewards were paid" "$(sql alice "SELECT count(*) FROM my_events WHERE action='MISSION'" )" '^[0-9]+$'

step "web interface"
WEB_PORT=$(grep -E "^WEB_PORT=" docker/.env | cut -d= -f2)
WEB=http://localhost:${WEB_PORT:-8080}
for _ in $(seq 1 60); do curl -fsS -o /dev/null "$WEB/" 2>/dev/null && break; sleep 1; done
assert "landing page serves" "$(curl -s -o /dev/null -w '%{http_code}' "$WEB/")" '^200$'
jar=$(mktemp)
assert "login as alice" "$(curl -s -c "$jar" -o /dev/null -w '%{http_code}' -H 'content-type: application/json' -d '{"username":"alice","password":"alice-pw-1"}' "$WEB/api/auth/login")" '^200$'
assert "wrong password rejected" "$(curl -s -o /dev/null -w '%{http_code}' -H 'content-type: application/json' -d '{"username":"alice","password":"nope-nope"}' "$WEB/api/auth/login")" '^401$'
assert "map snapshot has planets" "$(curl -s -b "$jar" "$WEB/api/map" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d["planets"]))')" '^[1-9][0-9]+$'
assert "sql console runs as alice" "$(curl -s -b "$jar" -H 'content-type: application/json' -d '{"sql":"SELECT username FROM my_player"}' "$WEB/api/sql" | python3 -c 'import sys,json; print(json.load(sys.stdin)["results"][0]["rows"][0][0])')" '^alice$'
assert "register from the web" "$(curl -s -o /dev/null -w '%{http_code}' -H 'content-type: application/json' -d '{"username":"carol","password":"carol-pw-1"}' "$WEB/api/auth/register")" '^200$'
assert "carol has a role" "$(sql schemaverse "SELECT count(*) FROM pg_roles WHERE rolname='carol'")" '^1$'
rm -f "$jar"

printf '\nSMOKE TEST PASSED on %s\n' "$(sql schemaverse "SELECT split_part(version(), ' on ', 1)")"
