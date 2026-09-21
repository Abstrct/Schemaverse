\i tests/_prelude.sql
SELECT plan(22);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
GRANT ALL ON ALL SEQUENCES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('alice-1');
SELECT id AS alice_ship FROM my_ships \gset
INSERT INTO my_fleets(name) VALUES ('alice-fleet');
SELECT id AS alice_fleet FROM my_fleets \gset
UPDATE my_fleets SET enabled = 't' WHERE id = :alice_fleet;
INSERT INTO my_query_store(name, query_text) VALUES ('q', 'SELECT 1');

SET SESSION AUTHORIZATION t_bob;
SELECT is((SELECT count(*)::int FROM my_ships), 0, 'bob sees none of alice''s ships');
SELECT is((SELECT count(*)::int FROM my_fleets), 0, 'bob sees none of alice''s fleets');
SELECT is((SELECT count(*)::int FROM my_query_store), 0, 'bob sees none of alice''s saved queries');
SELECT is((SELECT count(*)::int FROM my_player), 1, 'my_player is only bob');
SELECT is((SELECT count(*)::int FROM my_events WHERE player_id_1 = get_player_id('t_alice') AND NOT public), 0, 'alice''s private events are invisible');
SELECT is(upgrade(:alice_ship, 'ATTACK', 1), false, 'bob cannot upgrade alice''s ship');
SELECT is(refuel_ship(:alice_ship), 0, 'bob cannot refuel alice''s ship');
SELECT is(ship_course_control(:alice_ship, 10, NULL, point(0, 0)), false, 'bob cannot steer alice''s ship');
SELECT is(disable_fleet(:alice_fleet), false, 'bob cannot disable alice''s fleet');
UPDATE my_fleets SET script = 'PERFORM 1;' WHERE id = :alice_fleet;
-- row level security: the base tables are open, and show only what is yours
SELECT is((SELECT count(*)::int FROM ship), 0, 'RLS: bob sees no rows in ship');
SELECT is((SELECT count(*)::int FROM fleet), 0, 'RLS: bob sees no rows in fleet');
SELECT is((SELECT username FROM player), 't_bob', 'RLS: the player table is just you');
SELECT ok((SELECT count(*) > 0 FROM planet), 'RLS: every planet is visible');
SELECT throws_like($$SELECT fuel FROM planet$$, '%permission denied%', 'planet.fuel is hidden by a column grant');
SELECT throws_like($$SELECT * FROM planet_miners$$, '%permission denied%', 'planet_miners stays closed');
UPDATE ship SET name = 'pwned' WHERE id = :alice_ship;
SELECT throws_like($$UPDATE ship SET current_health = 1000 WHERE id = $$ || :alice_ship, '%permission denied%', 'health is not an updatable column');
SELECT throws_like($$SELECT register_player('t_eve', 'password-333')$$, '%permission denied%', 'players cannot register players');
SELECT throws_like($$INSERT INTO my_query_store(player_id, name, query_text) VALUES (get_player_id('t_alice'), 'x', 'x')$$, '%row-level security%', 'RLS blocks forging another player''s row');
SELECT is(move_ships(), false, 'move_ships refuses non-owners');

SET SESSION AUTHORIZATION schemaverse;
SELECT is((SELECT enabled FROM fleet WHERE id = :alice_fleet), true, 'alice''s fleet is still enabled');
SELECT is((SELECT name FROM ship WHERE id = :alice_ship), 'alice-1', 'bob''s UPDATE on alice''s ship touched nothing');
SELECT ok((SELECT 'security_invoker=true' = ANY(reloptions) FROM pg_class WHERE relname = 'my_ships'), 'my_ships runs as the caller');

SELECT * FROM finish();
ROLLBACK;
