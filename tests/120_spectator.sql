\i tests/_prelude.sql
SELECT plan(20);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players, spectator;
GRANT ALL ON ALL SEQUENCES IN SCHEMA :"tmpns" TO players, spectator;

-- alice writes a script and keeps it to herself
SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('alice-1');
DELETE FROM my_ships WHERE name = 'alice-1';  -- a scuttle is a public EXPLODE event
INSERT INTO my_fleets(name) VALUES ('miners');
SELECT id AS alice_fleet FROM my_fleets \gset
UPDATE my_fleets SET script = 'PERFORM 1;', script_declarations = 'x int;' WHERE id = :alice_fleet;
SELECT is((SELECT shared FROM my_fleets WHERE id = :alice_fleet), false, 'a new fleet is private');
SELECT is((SELECT count(*)::int FROM shared_fleets), 0, 'nothing is shared yet');

-- bob cannot publish her fleet for her
SET SESSION AUTHORIZATION t_bob;
UPDATE my_fleets SET shared = true WHERE id = :alice_fleet;
SELECT is((SELECT count(*)::int FROM shared_fleets), 0, 'bob cannot share alice''s fleet');

-- the spectator sees the public game and nothing private
SET SESSION AUTHORIZATION spectator;
SELECT is((SELECT count(*)::int FROM shared_fleets), 0, 'spectator: no shared fleets yet');
SELECT throws_like($$SELECT * FROM fleet$$, '%permission denied%', 'spectator: fleet is closed');
SELECT throws_like($$SELECT * FROM ship$$, '%permission denied%', 'spectator: ship is closed');
SELECT throws_like($$SELECT * FROM player$$, '%permission denied%', 'spectator: player is closed');
SELECT throws_like($$SELECT fuel FROM planet$$, '%permission denied%', 'spectator: planet.fuel is hidden');
SELECT throws_like($$SELECT * FROM my_query_store$$, '%permission denied%', 'spectator: saved queries are closed');
SELECT throws_like($$INSERT INTO my_fleets(name) VALUES ('x')$$, '%permission denied%', 'spectator: cannot write fleets');
SELECT throws_like($$SELECT register_player('t_eve', 'password-333')$$, '%permission denied%', 'spectator: cannot register players');
SELECT ok((SELECT count(*) > 0 FROM planets), 'spectator: sees the planets');
SELECT ok((SELECT count(*) >= 2 FROM player_profile WHERE username IN ('t_alice', 't_bob')), 'spectator: sees who plays');
SELECT is((SELECT count(*)::int FROM event WHERE NOT public), 0, 'spectator: private events are invisible');
SELECT ok((SELECT count(*) > 0 FROM event WHERE public AND action = 'EXPLODE' AND player_id_1 = get_player_id('t_alice')), 'spectator: public events are visible');
SELECT lives_ok($$SELECT * FROM trophy_case$$, 'spectator: trophy_case is readable');
SELECT lives_ok($$SELECT * FROM player_stats$$, 'spectator: player_stats is readable');

-- alice publishes, and the world can read the script
SET SESSION AUTHORIZATION t_alice;
UPDATE my_fleets SET shared = true WHERE id = :alice_fleet;
SET SESSION AUTHORIZATION spectator;
SELECT is((SELECT script FROM shared_fleets WHERE id = :alice_fleet), 'PERFORM 1;', 'spectator: a shared script is readable');
SELECT is((SELECT username FROM shared_fleets WHERE id = :alice_fleet), 't_alice', 'shared_fleets names the author');
SET SESSION AUTHORIZATION t_bob;
SELECT is((SELECT username FROM shared_fleets WHERE id = :alice_fleet), 't_alice', 'other players read shared_fleets too');

SELECT * FROM finish();
ROLLBACK;
