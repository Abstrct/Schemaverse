# Running Schemaverse with Docker

```bash
cp docker/.env.example docker/.env   # then set the three passwords
make up                              # PostgreSQL 19 beta + pgtap + pg_cron, schema, ticker, web
open http://localhost:8080           # register a player in the browser, or:
make player NAME=alice PASS=secret   # creates a player role and home planet
psql -h localhost -U alice schemaverse
```

Both ways of playing use the same PostgreSQL role. The web interface (`web/`,
SvelteKit) opens one connection per logged-in browser session, authenticated
as that player, so a browser can do exactly what psql can and nothing more.
It has a SQL console with schema-aware completion, a deck.gl map, fleet script
editing, and the trophies as their pins.

Other targets: `make logs` follows the ticker, `make psql` opens a shell as the
game owner (not a superuser; `docker compose exec db psql -U postgres` is), `make down` stops, `make reset` wipes the database, `make smoke` runs the
end-to-end test that CI runs, and `make test` runs the pgTAP suite in `tests/`
against the running stack (every test rolls itself back).

Registration goes through `register_player(name, password)`. The `registrar`
role can call it; give it a password with `ALTER ROLE registrar PASSWORD '...'`
if a front end needs to register players without being the owner.

Set `TIC_SECONDS=5` in `docker/.env` for a classroom pace. Set
`PG_IMAGE=postgres:18` if a 19 beta breaks something and you need to keep
teaching.

The ticker (`tic/`, Go) talks to the database over a shared unix socket that
the image trusts, which is how it runs each fleet script as its owning player
without holding player passwords. The published TCP port always requires a
password. One tic is `CALL tic_open()`, every enabled fleet script as its
player with `statement_timeout` set to the fleet's runtime, then
`CALL tic_close()`. `FLEET_CONCURRENCY` in `docker/.env` runs fleet scripts in
parallel; the default of 1 keeps the classic order.

Long interactive queries are cancelled after 60 seconds by the `referee`
pg_cron job, and `player_stats` is a materialized view refreshed every five
tics. The Perl daemons that did those jobs are in `legacy/`.

## Presets

```sql
SELECT apply_preset('classroom');   -- as the schemaverse owner: one-hour rounds, protected newcomers, generous start
SELECT apply_preset('public');      -- upkeep, progressive prices, spawn distance, grace period, stipend
SELECT apply_preset('classic');     -- the 2011 rules
```

`make psql` gets you an owner shell. Every lever is a row in `public_variable`.

## Production

```bash
# docker/.env: strong passwords, DOMAIN, ACME_EMAIL, TIC_SECONDS=60
docker compose -f docker/compose.yml -f docker/compose.prod.yml up -d --build
```

The overlay puts Caddy in front of the web interface with automatic TLS on
`DOMAIN`, removes the web port from the host, runs a nightly `pg_dump` into
the `backups` volume, and passes memory and async I/O settings to Postgres.
psql players connect to port 5432 directly; give Postgres a certificate in
`docker/postgres/tls/` and set `PG_SSL=on` so that connection is encrypted
too.

Restore: `pg_restore -U postgres -d schemaverse --clean --create <dump>` after
`psql -U postgres -f roles-<stamp>.sql`.

Sessions in the web interface live in the web process; restarting it logs
everyone out, which is by design (no passwords are stored).
