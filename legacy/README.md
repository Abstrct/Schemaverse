# Legacy daemons

The three Perl programs that ran schemaverse.com from 2011 to 2017. Kept for
history; none of them is used by the Docker stack.

- `tic.pl` — the game clock. Replaced by `tic/` (Go) plus the `tic_open()` and
  `tic_close()` procedures in the schema.
- `ref.pl` — cancelled player queries that ran too long. Replaced by the
  `referee` pg_cron job (`schema/deploy/cron-referee.sql`) and by the runner's
  per-fleet timeout.
- `stat.pl` — kept `player_round_stats` fresh. Replaced by the `player_stats`
  materialized view refreshed from `tic_close()`.
