# Schemaverse Modernization Plan

Drafted 2026-09-20 from a full read of the repository at commit `1ccd928`. Decisions from the same day are folded in below.
This is a living document. Sections are ordered as phases; each phase ends with
something runnable so the project never sits in a half-migrated state.

---

## 0. Where things stand

**What exists**

| Piece | Location | State |
|---|---|---|
| Game schema (88 sqitch changes) | `schema/` | Last touched 2016. Targets PostgreSQL 9.3. All 88 `verify/` scripts are empty stubs. |
| Ticker | `tic.pl` | Perl + DBI daemon. Reconnects as every player each tic to run fleet scripts. |
| Referee | `ref.pl` | Polls `pg_stat_activity` every 30s and cancels long queries. |
| Stats | `stat.pl` | Busy loop that recomputes one player's round stats at a time. |
| Web client "TrainingWheels" | `clients/TrainingWheels/` | PHP short tags, jQuery 1.2.6, d3 v2, CoffeeScript. Hardcodes `db.schemaverse.com`. |
| Notification client | `clients/SchemaverseOutputStream/` | Python 2. |
| Trophies | `trophies/*.sql` | 29 scripts, several reference `event_archive`, which no longer exists. |
| Items | `items/` | Dead code; item tables were removed in 2013. |

**Things a fresh deploy will hit today** (items 1 and 11 confirmed by running the Phase 0 smoke test on PostgreSQL 19 beta 3; the rest confirmed by reading)

1. `trigger-destroy_ship` deletes from `ships_near_planets` and `ships_near_ships`. Neither table exists in the sqitch plan. PL/pgSQL only resolves table names at runtime, so the first ship to die aborts the ticker's health transaction with "relation does not exist".
2. TrainingWheels queries `my_query_store` for saved queries. Not in the schema.
3. Trophies branch on `event_archive`. Not in the schema. The `trophy_script_update` trigger is also created disabled, so trophy approval never compiles scripts.
4. `create_ship` hardcodes a 2000 ship cap while the `MAX_SHIPS` variable says 1000, and its error message says the opposite of what it checks.
5. `create_ship` silently teleports a ship to the player's planet instead of rejecting a bad location (the `RETURN NULL` is commented out).
6. `upgrade()` and `refuel_ship()` never check that the caller owns the target ship or fleet. You pay, but you can upgrade anyone.
7. Passwords: the client builds an MD5 hash and stores it in `player.password`, then the trigger passes that string to `CREATE ROLE`. PostgreSQL 14+ defaults to SCRAM and a `scram-sha-256` line in `pg_hba.conf` rejects MD5-stored roles. `my_player` also exposes the hash column to the player.
8. 14 of 30 `SECURITY DEFINER` functions do not pin `search_path`. That is the textbook privilege-escalation vector for definer functions, and players are hostile by design.
9. `round_control` runs `COPY ... TO '<file>'`, which needs superuser or `pg_write_server_files` and a writable path inside the container.
10. `tic.pl` runs `CLUSTER ship` and `VACUUM ship` every tic under an `ACCESS EXCLUSIVE` lock. Autovacuum has handled this well for a decade.
11. `my_ships` has an `ON DELETE` rule that marks a ship destroyed, but `permissions.sql` never grants players DELETE on the view, so scuttling a ship is impossible from a player session. Confirmed by the smoke test on 2026-09-21.
12. `current_player_stats` scans the entire `event` table per row of `player`, plus a self-join on `ship_flight_recorder`. It is the source of the "stats are slow" comments in the CHANGELOG.

**Things that are genuinely good and worth keeping**

- The core idea: every player is a real database role and the game's security *is* PostgreSQL's security. Nothing in the modernization should introduce a privileged web path that bypasses this.
- Fleet scripts as PL/pgSQL functions owned by the player.
- Per-player `NOTIFY` error channels. It is a great way to teach LISTEN/NOTIFY.
- Geometric `point` columns with GiST indexes for range queries.
- sqitch. It is still maintained and the deploy/revert/verify split is right for a schema-is-the-app project.
- The trophy system as user-contributed SQL.

---

## 1. Phase 0: Make it run again (Docker + CI)

Goal: `docker compose up` gives anyone a playable instance in under two minutes. This unblocks every later phase and is the deliverable schools need.

**Layout**

```
docker/
  compose.yml
  postgres/
    Dockerfile          # FROM postgres:${PG} (19beta3 default, 18 in CI), adds pg_cron + pgtap from PGDG
    initdb/01-roles.sh  # creates schemaverse owner role from env
    pg_hba.conf         # scram-sha-256 for players, trust only on the docker network
    postgresql.conf     # autovacuum tuned for ship/event, statement_timeout defaults
  sqitch/               # uses the official sqitch/sqitch image, mounts ./schema
  tic/                  # the ticker runner (see Phase 2 for what it becomes)
  web/                  # Phase 3
```

**Services**

| Service | Image | Notes |
|---|---|---|
| `db` | custom `postgres:19beta3` | Port 5432 published so students connect with `psql` directly. Healthcheck on `pg_isready`. `POSTGRES_VERSION` build arg so CI can also build 18. |
| `migrate` | `sqitch/sqitch` | One-shot: `sqitch deploy`, then `sqitch verify`. Depends on `db` healthy. |
| `tic` | `debian:trixie-slim` + packaged DBD::Pg | Runs `tic.pl` unchanged. It is a stopgap so Phase 0 could ship in a day; the Go runner in Phase 2 replaces it and the Perl files move to `legacy/`. |
| `web` | Phase 3 | |
| `pgadmin` / `pgweb` | optional profile | Useful in classrooms. |

**Also in this phase**

- `.env.example` with `POSTGRES_PASSWORD`, `SCHEMAVERSESLEEP`, `ROUND_LENGTH`.
- A `justfile` or `Makefile`: `up`, `down`, `reset`, `psql`, `new-player NAME`, `test`.
- A `scripts/new_player.sh` that inserts into `player` as the owner role so a teacher can bulk-create a class.
- GitHub Actions: build the image, deploy the schema, create two players, run 10 tics, assert ships moved and one was destroyed. This single smoke test would have caught item 1 above.
- Fix only what blocks the smoke test in this phase. Everything else is Phase 1.

**PostgreSQL version**: decided 2026-09-20. Run on **PostgreSQL 19 beta** (`postgres:19beta3` today, tracking each beta and the GA release when it lands) with **18** in the CI matrix as the safety net. The point of the project is to show off what Postgres can do, so the public server follows the newest release. The PGDG apt repository already ships `postgresql-19-pgtap` and `postgresql-19-cron`, so the image can install both from packages. Do not chase 9.3 compatibility.

---

## 2. Phase 1: Schema audit and repair

Goal: a correct, tested schema on modern PostgreSQL with no behaviour changes players would notice.

**Correctness fixes** (the list from section 0, plus anything the smoke test surfaces)

- Remove the dead `ships_near_*` deletes from `destroy_ship`.
- Decide on `event_archive`: either add a partitioned `event` table keyed by round (recommended, see Phase 2) or strip the archive branch from the trophies.
- Add `my_query_store` as a real per-player table with RLS, since the new UI wants it too.
- Reconcile `MAX_SHIPS`, fix the `create_ship` message, restore the location rejection.
- Add ownership checks to `upgrade`, `refuel_ship`, and `disable_fleet`.
- Grant DELETE on `my_ships` so the scuttle rule is reachable, and decide whether scuttling should refund the ship price (it does today, via `destroy_ship`).
- Pin `SET search_path = public, pg_temp` on every `SECURITY DEFINER` function via the function's `SET` clause rather than a statement in the body.
- Replace string-concatenated DDL (`CREATE ROLE ' || NEW.username`) with `format('%I', ...)`.
- Replace the `RANDOM()*1000000` dollar-quote tag in `fleet_script_update` and `trophy_script_update` with `gen_random_uuid()`.
- Drop the password column from `player` and from `my_player`. Role authentication is the password. Registration becomes a function that calls `CREATE ROLE ... PASSWORD %L` with the plaintext over TLS and lets the server SCRAM-hash it.
- Move `round_control`'s CSV export into a table (`event` partition detach) instead of `COPY TO` file.
- Stop requiring `schemaverse` to be a superuser. Today it must be: `permissions.sql` revokes on `pg_proc`, and `round_control` uses `DISABLE TRIGGER ALL`, which touches system FK triggers. Replace the former with nothing (it never hid anything useful) and the latter with `session_replication_role = replica` or explicit trigger names, then run the owner as a plain `CREATEROLE` login.

**Test harness**

- Add pgTAP to the image. Write real `verify/` scripts for the 88 changes (most are one-liners: `has_table`, `has_function`, `has_column`).
- A `tests/` directory of pgTAP scenario tests run by CI: ship creation charges balance, attack respects range, mining respects `mine_limit`, fleet script cannot escape its dollar-quote, player A cannot see player B's ships. *Done: six files, 68 assertions, run by `scripts/test.sh` since the image has pgtap but no `pg_prove`.*

**Sqitch hygiene**

- Retag the plan at `v1.0` for the 2016 schema, then add changes on top. Do not rewrite history; existing installs may exist.
- Remove `schema/sqitch.conf` from the repo (it is a personal config that is also gitignored, and it currently wins over the sample).

---

## 3. Phase 2: Use modern PostgreSQL

This is the phase that makes the game a better teaching tool, because the mechanisms become the ones people actually use in 2026.

| Old mechanism | Modern replacement | Why it matters |
|---|---|---|
| `my_ships`, `my_fleets`, `my_events` views + `RULE`s + `general_permission_check` trigger | **Row Level Security** on the base tables, views declared `WITH (security_invoker = true)` | Rules are a footgun and rarely taught. RLS is what students will meet at work. *Done 2026-09-21 as an additive change: policies plus column grants on eight tables, seven views flipped. The rules and the permission trigger stay for now; they are harmless under RLS and removing them is a later cleanup.* |
| `id_dealer` trigger + hand-made sequences | `GENERATED ALWAYS AS IDENTITY` | Removes a trigger and the sequence permission dance. |
| `location_x`/`location_y` duplicated next to `location point` | Generated columns, or drop them | Move `x`/`y` to `GENERATED ALWAYS AS ((location)[0]) STORED` for backwards compatibility, then deprecate. |
| Perl orchestration in `tic.pl`, `ref.pl`, `stat.pl` | Two SQL procedures, `tic_open()` and `tic_close()`, a small **Go** runner for the fleet phase, and **pg_cron** for everything on a clock | Perl is gone (decided 2026-09-21). See "The tic, rewritten" below. |
| Reconnecting as each player, every tic | A small pool of persistent per-player sessions authenticated over the trusted local socket, reused across tics, with `SET LOCAL statement_timeout = <fleet runtime>` per fleet | **Not** `SET ROLE` from one owner connection: a fleet script can run `RESET ROLE` and get the owner's privileges back, because role switching is escapable by design. Fleet scripts must run in sessions whose *authenticated* user is the player. The socket-trust arrangement in `docker/compose.yml` already provides that without passwords. The same rule binds the web backend in Phase 3. |
| `ref.pl` | `ALTER ROLE <player> SET statement_timeout = '60s'` at creation, plus the per-fleet `SET LOCAL` above | Server-enforced. `ref.pl` stays only as a backstop until pgTAP proves a script cannot lift its own timeout mid-statement. |
| `stat.pl` busy loop | Materialized views refreshed at the end of `tic()`, or `pg_ivm` | Stats become one `REFRESH MATERIALIZED VIEW CONCURRENTLY`. |
| Unbounded `event` table, `event_archive` gone | `event` partitioned by `round_id`; `round_control` creates the next partition and keeps the old one | Archive becomes free, trophies work again, stats stay fast. *Done 2026-09-21; `event_archive` is a view over earlier rounds.* |
| `CLUSTER` + `VACUUM` per tic | Per-table autovacuum settings | Removes an exclusive lock from the hot path. |
| `round_control()` polled by tic | `pg_cron` schedule | Round rollover independent of tic cadence. |
| `pg_stat_activity` for `online_players` | Same, but `GRANT pg_read_all_stats` is no longer needed since 10 | Verify and simplify. |
| `numeric_value integer` in `variable` | `jsonb` settings with a typed accessor | Lets scenario presets (Phase 4) be one document. |
| `character(30)` action codes with an FK | `enum` or a lookup with `text` | Minor, but `character(n)` trailing-space semantics bite students. |
| Fleet script body executed by name | Same, but with `gen_random_uuid()` dollar tags and `SET LOCAL` guards | See Phase 1. |

**The tic, rewritten**

`tic.pl` does three different jobs and they want three different homes.

1. *Game physics*: move ships, resolve actions, mine, settle health, advance `tic_seq`. This is pure SQL over tables the owner controls. It becomes `CALL tic_open()` (round check, movement) and `CALL tic_close()` (actions, mining, health, stats refresh, `NOTIFY tic`). Procedures can commit between phases, so each phase gets its own transaction as today.
2. *Fleet scripts*: run every enabled fleet's function as its owning player with that fleet's runtime as the timeout. This needs a session authenticated as the player (see the `RESET ROLE` note above), and it wants concurrency and hard deadlines. That is a **Go** program: ~200 lines with `pgx`, one goroutine per fleet, `context.WithTimeout` per fleet, connections over the trusted socket as the player, results written back via `fleet_success_event` / `fleet_fail_event` exactly as now. Static binary, 10 MB image, no runtime to install. The main loop is `tic_open` → fleets → `tic_close` → sleep.
3. *Clocks*: round rollover, stat refreshes, planet regeneration. These are **pg_cron** jobs running as the owner. `SELECT cron.schedule('round', '0 * * * *', 'CALL round_control()')`. The image already ships pg_cron and it is a good thing to show a class.

Decision to make when this is built: fleet scripts today run sequentially, ordered by username. The Go runner can run them concurrently. Concurrency is fairer and faster but changes semantics when two fleets contend for the same target; the locks in the schema are table-level and were written for a single writer. Start sequential, switch on a flag once pgTAP covers the contention cases.

`ref.pl` is replaced by the per-fleet context deadline plus `ALTER ROLE ... SET statement_timeout`. `stat.pl` is replaced by a materialized view refreshed in `tic_close()`.

**Bleeding edge: features to showcase because we are on 19**

The game is a demo of Postgres as much as it is a game. Each of these should get a short "how it works" note in the docs when it lands, so a student can `\d+` their way to it.

- Asynchronous I/O (18) with `io_method = io_uring` on Linux hosts, plus `pg_aios`. The tic's full-table passes over `ship` and `event` are exactly the workload it helps, and it is a good story for the classroom.
- Virtual generated columns (18): `location_x`/`location_y` become `GENERATED ALWAYS AS ((location)[0]) VIRTUAL`, so the old column names keep working at zero storage cost.
- `RETURNING OLD.* / NEW.*` (18) in `attack`, `repair`, and `upgrade` so an action returns before-and-after state in one statement.
- Temporal `WITHOUT OVERLAPS` primary keys (18) for planet ownership history: `(planet_id, valid_period WITHOUT OVERLAPS)` gives the map a correct territory replay without an event scan.
- `uuidv7()` (18) for session and fleet-script tags.
- `pg_stat_statements` and the 18 per-backend I/O stats surfaced in a "what is my fleet script costing" panel.
- OAuth authentication (18) as a second login path for the web UI next to SCRAM, so a school can use its own identity provider.
- Whatever 19 finalises: track the release notes and pick two features to build on before GA. Skip-scan B-tree lookups (18) already help the `event` indexes.

**Things to add because they are now cheap**

- `map_snapshot()` and `map_delta(since_tic)` functions returning `jsonb` for the UI, built with `jsonb_agg`. RLS makes them automatically fog-of-war correct: they return exactly what `ships_in_range` would.
- A `tic` NOTIFY channel that every client can LISTEN on, replacing polling.
- `pg_stat_statements` enabled in the image so an instructor can show a class which fleet scripts are expensive. That is a teaching moment the old design could not offer.
- `EXPLAIN` access for players on their own queries (it already works; document it).

**Keep unchanged**

- Function names and signatures players call: `ship_course_control`, `attack`, `mine`, `repair`, `upgrade`, `refuel_ship`, `convert_resource`, `get_*_variable`. Existing wiki examples must keep working.
- The `my_*` view names, now backed by RLS.

---

## 4. Phase 3: New web interface and map

**Visual identity**: the interface is built from the DEF CON 19 pin system. Two inks, paper background, thick frames, the rotated-word headline lockup, ship silhouettes as map glyphs, and every trophy rendered as its pin. `docs/BRAND.md` has the tokens and rules; `docs/brand/` has the exported assets.

**Design rule**: a browser session has exactly the powers of a `psql` session as that role, no more. The backend never holds a privileged path that acts on behalf of a player. That keeps the game honest and keeps "you can hack it if you can hack Postgres" true.

**Architecture**

```
browser ──HTTPS──> web (SvelteKit + TS)
                     │
                     ├─ /api/sql        run arbitrary SQL as the player  (pool + SET LOCAL ROLE)
                     ├─ /api/events     SSE stream: LISTEN <player channel>, LISTEN tic
                     ├─ /api/map        calls map_snapshot()/map_delta() as the player
                     └─ /api/auth       verifies by opening a real connection as that role
                     │
                     └──────> db (same Postgres students psql into)
```

- **Auth**: login attempts a real connection as the role with the given password. Success issues a session cookie and keeps that authenticated connection (or the credential to reopen it) in server-side session state. Every query the player runs goes down a connection authenticated *as that player*. The backend must not use a shared privileged pool with `SET ROLE`, for the same `RESET ROLE` reason as the ticker. No password is stored anywhere but the role catalog and the encrypted session.
- **Query console**: CodeMirror 6 (chosen over Monaco: schema-aware completion built in, far smaller) with PostgreSQL grammar, schema-aware completion fed from `information_schema` as the player, result grid with type-aware formatting, saved queries in `my_query_store`, a "what does this view do" panel that shows `pg_get_viewdef` for the `my_*` views. The console is the training-wheels core, so it gets the polish.
- **Tutorial track**: a `mission` table in the schema. Missions are checked by SQL predicates, e.g. "you have run a SELECT on my_ships", "you own a ship with attack > 5", "your fleet script ran without error". Completing one awards balance. This directly addresses new-player onboarding and is entirely in the database, so it works from psql too.
- **Map**: deck.gl with an `OrthographicView`. `ScatterplotLayer` for planets, `IconLayer` or `TextLayer` for ships using the player symbol and RGB already in the `player` table, `LineLayer` for flight-recorder trails, `PolygonLayer` Voronoi for territory. deck.gl handles 100k points with pan and zoom on the GPU, which matters because the universe is 19.4 million units wide and rounds can reach thousands of ships. Fallback if deck.gl feels heavy: Canvas 2D with `d3-zoom`, which is fine to roughly 20k sprites.
- **Map modes**
  - *Live*: what you can see now, updated on each `tic` NOTIFY via `map_delta`.
  - *Replay*: scrub through `my_ships_flight_recorder` and `my_events` for the current round. The old visualizer did this and it was the best part; keep the idea, rebuild it.
  - *Galaxy*: public, planet ownership only, delayed by N tics so it leaks nothing tactical. Good for a classroom projector.
- **Notifications**: `NOTIFY` payloads shown as toasts and appended to a log pane. This replaces `SchemaverseOutputStream`.
- **Deploy**: one container, static assets plus a Node server, in the same compose file.

Stack alternatives considered and set aside: PostgREST is a natural fit for the ethos and could be added later for a typed API, but the console needs arbitrary SQL execution anyway, so a single small backend is simpler to start.

---

## 5. Phase 4: Gameplay for new players

The problem stated: established players dominate. Three causes in the current rules, and levers for each. Every lever should be a `variable` row so an instructor can set a classroom preset.

**Cause 1: compounding economy.** Fuel converts 1:1 to money, upgrades have flat prices, and `FLEET_RUNTIME` at 10,000,000 is the only real sink. Whoever mines first snowballs.

- Progressive upgrade pricing: cost scales with the ship's current stat.
- Upkeep: each living ship costs a small amount of fuel per tic. A 2000-ship fleet becomes a choice, not a default.
- Planet regeneration proportional to how few ships the owner has, replacing the random `+1,000,000` hack in `tic.pl`.

**Cause 2: no protection for arrivals.** A new player's home planet is placed randomly and can be camped immediately.

- Spawn placement: new home planets are placed at least `SPAWN_MIN_DISTANCE` from any planet owned by a player above median fleet size.
- Grace period: ships within `HOME_SAFE_RADIUS` of your home planet cannot be attacked for your first `GRACE_TICS`.
- Late-joiner stipend: starting balance and fuel scale with how far the round has progressed.

**Cause 3: rounds are long and one league.** A player who joins on day five of a seven-day round cannot catch up.

- Shorter default `ROUND_LENGTH` for the public server, with an all-time leaderboard across rounds so veterans still have something to chase.
- Classroom preset: one-hour rounds, 10-second tics, no upkeep, generous stipend.
- Optional teams: an `alliance` table so newcomers can join a veteran's side, with shared `ships_in_range` visibility. This partly restores what "trade" was for.

**Also worth doing**

- Missions and tutorial trophies (Phase 3) so a first session has goals.
- Make trophy approval work again and add a handful aimed at first-round players.
- Keep every change reversible via `variable` so the public server and a school instance can run different rules on the same code.

---

## 6. Phase 5: Public deployment, docs, community

- Production compose overlay: TLS termination, Postgres data volume on a snapshotting disk, `pg_basebackup` or `pgBackRest` nightly, `pg_stat_statements` and basic Prometheus exporters.
- Rewrite `README` and `INSTALL.org` as `README.md` with three paths: play on the public server, run it for a class, hack on it.
- Move the GitHub wiki content into `docs/` so it versions with the schema. The wiki is the only reference for functions and views and it is unversioned.
- Security page that is honest: this is a hostile-player system by design, here is the threat model, here is what a report should include.
- Archive `items/`, the two Perl daemons, and TrainingWheels under `legacy/` once their replacements exist, rather than deleting. They are history worth keeping.

---

## 7. Sequencing and decisions

**Order**: 0 → 1 → 2 → 3 → 4 → 5, but Phase 3 frontend work can start once Phase 2 delivers `map_snapshot()` and RLS, and Phase 4 balance work is mostly `variable` rows and can trail everything.

**Decisions made 2026-09-20**

1. PostgreSQL: 19 beta on the public server, 18 in CI. Bleeding edge on purpose.
2. Sqitch stays.
3. Web stack: SvelteKit + TypeScript + deck.gl + Monaco.
4. Public server: clean round 1, no data migration from the old database.
5. Visual identity: the DEF CON 19 pins and the elephant logo are the design system. See `docs/BRAND.md`.

**Still open**

- Rule changes: which of the Phase 4 levers become defaults on the public server versus only in the classroom preset.
- Which PG19 features to showcase first. Candidates are listed in Phase 2 under "Bleeding edge".

**Status 2026-09-21, Phase 5 in the repository.** `README.md` rewritten with the three paths (play, run for a class, hack on it), `docs/PLAYING.md` as the player reference, TrainingWheels and the Perl daemons under `legacy/`, and `docker/compose.prod.yml` with Caddy TLS, nightly backups and Postgres tuning. What remains needs a server: standing the public instance up, DNS, and the honest security page once the threat model is written against the live configuration. The wiki content is not imported; `docs/PLAYING.md` replaces the parts that mattered.

**Status 2026-09-21, Phase 4 levers and missions are in the schema.** Every lever from section 5 exists as a `variable` row, off by default, with `apply_preset()` for the classic, public and classroom sets. The mission track is eleven rows in `mission`, claimed by `check_missions()` and by the tic. Which levers the public server turns on remains the open decision; the classroom preset is ready.

**Status 2026-09-21 (later), Phase 3 second cut.** The interface moved to the screen edition of the pin system (`docs/BRAND.md`, "Screen edition"): a Canvas 2D map with lit spheres, particle streams and the traced pin ship replaces deck.gl; the map is click-to-SQL (every click shows its statement before it runs); the mission track is the Academy, drawn as pins with the Boss as coach; a round replay page scrubs `my_ships_flight_recorder` and narrates `my_events`; fleets gained snippet blocks. deck.gl is no longer a dependency. The ten concept boards that drove this are on the design canvas noted in the session memory.

**Status 2026-09-21, Phase 3 first cut is running.** `web/` is a SvelteKit app with the console, map, fleets and trophies pages on the pin design system, wired into `docker compose` as the `web` service and into the smoke test. CodeMirror 6 replaced Monaco in the plan (schema-aware SQL completion out of the box, a tenth of the size). Still to do in Phase 3: the replay and galaxy map modes, the mission track, a help page, and design polish across viewports.

**Status 2026-09-21, Phase 2 in progress.** Done: the ticker rewrite (Perl retired to `legacy/`, `tic_open()`/`tic_close()`, Go runner in `tic/`, referee as pg_cron, `player_stats` materialized, autovacuum tuned); row level security on eight base tables with the `my_*` views flipped to `security_invoker`; the owner is no longer a superuser. Smoke and pgTAP (83 assertions) pass on 19 beta 3 and 18. Event partitioning by round is done (identity id, `event_archive` view, `round_control` keeps history, `ensure_event_partition` self-heals). `map_snapshot()` and `player_badge()` are in, which is what Phase 3 needs from the schema. Identity and generated columns on the remaining tables are deferred behind Phase 3; they are polish, the web interface is the deliverable.

**Status 2026-09-21, Phase 1 done as well.** Fourteen sqitch changes on top of the `@v1.0` tag: search_path pinned on all 30 definer functions, `create_ship` honours `MAX_SHIPS` and rejects bad locations, ownership checks on `upgrade`, `refuel_ship` and `disable_fleet`, uuid dollar-quote tags for fleet and trophy scripts, `round_control` without `COPY` or `DISABLE TRIGGER ALL`, `register_player()` with server-side SCRAM hashing and a `registrar` role, `player.password` dropped, `my_query_store` under row level security, DELETE granted on `my_ships`. All 103 verify scripts are real. Deploy, revert to `@v1.0`, and redeploy are proven. A 68-assertion pgTAP suite in `tests/` runs with `make test` and in CI.

Left in Phase 1 on purpose: the owner is still a superuser (needed by `permissions@v1.0`'s `pg_proc` revoke; it goes away with the RLS rewrite in Phase 2), and the trophy scripts still reference `event_archive` (fixed by event partitioning in Phase 2).

**Status 2026-09-21**: Phase 0 is done. `make smoke` passes on PostgreSQL 19 beta 3: fresh cluster, all 88 changes plus the `destroy_ship` rework deploy, round_control builds a 500-planet universe, two players buy ships, one mines and one flies, lethal damage destroys a ship inside the ticker's health pass, the ticker keeps running. CI runs the same script on 19 beta 3 and 18.

**Next**: Phase 1 repairs, then the Go ticker as the opening move of Phase 2.
