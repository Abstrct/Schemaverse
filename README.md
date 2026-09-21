<p align="center"><img src="docs/brand/logo-wordmark.png" alt="Schemaverse" width="360"></p>

# Schemaverse

A space strategy game implemented entirely inside PostgreSQL. Every player is
a database role. Buy ships with `INSERT`, steer them with a function call, read
the battle in a view, and if your PL/pgSQL is strong, write a fleet script and
let the database command your fleet for you.

People play it to learn SQL, to teach SQL, to poke at Postgres security, and
to build map UIs. This edition runs on **PostgreSQL 19** (18 in CI), on
purpose: the game is a showcase of what modern Postgres can do.

## Play

Two doors, one account. Your username is a PostgreSQL role.

- **psql**: `psql -h <server> -U <you> schemaverse`
- **browser**: the web interface has a SQL console with completion, a live
  map you can command by clicking (every click shows the SQL it wrote),
  a round replay, fleet script editing, the mission track and trophies. It opens a connection as
  *you*, so it can do exactly what psql can and nothing more.

Start with `SELECT * FROM my_missions;` or the Missions tab. The reference is
in [docs/PLAYING.md](docs/PLAYING.md).

## Run it yourself

Everything runs in Docker. A class, a hackathon, or your laptop:

```bash
git clone https://github.com/Abstrct/Schemaverse.git
cd Schemaverse
cp docker/.env.example docker/.env   # set the three passwords
make up                              # PostgreSQL 19 + schema + ticker + web
open http://localhost:8080
```

`make player NAME=alice PASS=secret` creates a player from the command line.
`make smoke` runs the end-to-end test, `make test` the pgTAP suite. Details,
including the classroom preset (one-hour rounds, protected newcomers) and
production deployment with TLS and backups, are in
[docker/README.md](docker/README.md).

## Hack on it

- `schema/` is a [sqitch](https://sqitch.org) project. `sqitch.plan` is the
  history of the game; every change has a deploy, a revert and a verify script.
- `tic/` is the ticker, in Go: it sequences `tic_open()`, every fleet script
  as its player, and `tic_close()`.
- `web/` is the SvelteKit interface.
- `tests/` is pgTAP. `trophies/` are the classic trophies as SQL.
- `docs/MODERNIZATION_PLAN.md` is the plan this edition follows, and
  `docs/BRAND.md` is the design system, derived from the DEF CON 19 pins.
- `legacy/` holds the 2011-2017 Perl daemons and PHP client for history.

This game was created to learn about security in Postgres, and it is played
by people trying to break it. Run it on something you can rebuild.

-Abstrct · [schemaverse.com](https://schemaverse.com)
