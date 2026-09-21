# Playing Schemaverse

Connect as your player role (`psql -h <server> -U <you> schemaverse`) or log in
to the web interface. Everything below works in both.

## The clock

The game advances in **tics** (`SELECT last_value FROM tic_seq;`), usually one
a minute. Each tic: ships move, then every enabled fleet script runs as its
owner, then queued actions resolve (attack, repair, mine), planets regenerate,
damage settles, and `NOTIFY tic` fires. Rounds last `ROUND_LENGTH`; at the end
the universe is rebuilt and everyone starts over with trophies awarded for the
round that ended. `SELECT * FROM public_variable;` lists every rule value.

## What you can see

| Relation | What it is |
|---|---|
| `my_player` | You: balance, fuel reserve, symbol, colour. |
| `my_ships` | Your living ships with their controls. `INSERT` to buy, `UPDATE` to rename, steer or set an action, `DELETE` to scuttle. |
| `ships_in_range` | Other players' ships inside one of your ships' range. |
| `planets` | Every planet. `mine_limit` is how many ships can mine it per tic. |
| `planets_in_range` | Planets inside your ships' range, with distance. |
| `my_fleets` | Your fleet scripts. |
| `my_events` | What happened to you, plus public events. `read_event(id)` makes a sentence of one. |
| `event_archive` | Earlier rounds. |
| `my_missions` | The tutorial track and what you have completed. |
| `my_query_store` | Your saved queries. |
| `player_stats`, `current_stats`, `online_players`, `trophy_case` | Standings and who is around. |

Since 2026 the base tables (`ship`, `planet`, `fleet`, `event`, `player`,
`variable`) are readable too: row level security shows you your own rows, and
`\d+ my_ships` shows you exactly how the view is built.

## What you can do

| Call | Effect |
|---|---|
| `INSERT INTO my_ships(name) VALUES ('x')` | Buy a ship on one of your planets (1000). Skills default to 5 each; pass `attack, defense, engineering, prospecting` summing to at most 20. |
| `SELECT ship_course_control(ship, speed, direction, destination point)` | Set a course. Give a direction *or* a destination. Ships burn fuel to change velocity. |
| `UPDATE my_ships SET action = 'MINE', action_target_id = planet WHERE id = ship` | Mine every tic while in range. Also `'ATTACK'` and `'REPAIR'` with a ship as target. |
| `SELECT attack(ship, enemy_ship)`, `repair(ship, ship)`, `mine(ship, planet)` | The same actions, once, right now. One action per ship per tic. |
| `SELECT refuel_ship(ship)` | Fill a ship from your reserve. |
| `SELECT upgrade(ship, 'ATTACK', n)` | Buy skill, `MAX_HEALTH`, `MAX_FUEL`, `MAX_SPEED` or `RANGE`. Prices in `price_list`. |
| `SELECT upgrade(fleet, 'FLEET_RUNTIME', minutes)` | Buy running time for a fleet script. The first minute is free. |
| `SELECT convert_resource('FUEL', n)` | Fuel to money, or `'MONEY'` the other way. |
| `SELECT check_missions()` | Claim any mission you have completed. |
| `SELECT set_numeric_variable(name, n)` | Your own persistent variables, for scripts. |

Mistakes and refusals arrive on your error channel: `LISTEN <channel>` with the
channel from `my_player.error_channel`, or watch the web interface.

## Fleet scripts

A fleet is a PL/pgSQL script that runs as you every tic, for as long as its
purchased runtime allows.

```sql
INSERT INTO my_fleets(name) VALUES ('miners');
UPDATE my_fleets SET
  script_declarations = 's RECORD; target integer;',
  script = $$
    FOR s IN SELECT id FROM my_ships WHERE action IS NULL LOOP
      SELECT planet INTO target FROM planets_in_range WHERE ship = s.id ORDER BY distance LIMIT 1;
      IF target IS NOT NULL THEN
        UPDATE my_ships SET action = 'MINE', action_target_id = target WHERE id = s.id;
      END IF;
    END LOOP;
  $$,
  enabled = true
WHERE name = 'miners';
SELECT upgrade(id, 'FLEET_RUNTIME', 1) FROM my_fleets WHERE name = 'miners';
```

Scripts compile once per tic. Failures are logged as `FLEET_FAIL` events with
the error text; a script that runs past its runtime is disabled.

## Conquest

A planet belongs to whoever mined it most in a tic, ties to the holder. Ships
can only be built on planets you hold. Planet fuel regenerates each tic up to
`PLANET_REGEN_CAP`.

## New players

Depending on the server's preset, newcomers may get a stipend, a protected
home zone for `GRACE_TICS`, and spawn placement away from big fleets. Ask
`SELECT name, numeric_value, description FROM public_variable WHERE name IN
('GRACE_TICS','LATE_JOIN_STIPEND','SHIP_UPKEEP','UPGRADE_PRICE_SCALE');`.

## Trophies

`SELECT * FROM trophy;` shows every trophy and the SQL that decides it. Propose
one with an `INSERT`; the owner approves it. Winners appear in `trophy_case`.
