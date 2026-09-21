\i tests/_prelude.sql
-- Exercises the per-tic functions the ticker calls: movement, mining, combat.
SELECT plan(12);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
GRANT ALL ON ALL SEQUENCES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('miner', 0, 0, 0, 20);
INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('scout', 20, 0, 0, 0);
SELECT id AS miner FROM my_ships WHERE name = 'miner' \gset
SELECT id AS scout FROM my_ships WHERE name = 'scout' \gset
SELECT id AS home FROM planets WHERE conqueror_id = get_player_id('t_alice') \gset
SELECT location AS start FROM my_ships WHERE id = :scout \gset

-- movement
SELECT is(ship_course_control(:scout, 500, NULL, point((location[0] + 50000)::int, location[1]::int)), true, 'course set') FROM my_ships WHERE id = :scout;
SET SESSION AUTHORIZATION schemaverse;
-- A ship cannot move in the tic it was built; pretend it was built earlier.
UPDATE ship SET last_move_tic = 0 WHERE id = :scout;
SELECT is(move_ships(), true, 'move_ships runs for the owner');
SELECT ok((SELECT (location <-> :'start'::point) > 0 FROM ship WHERE id = :scout), 'the scout moved');
SELECT is((SELECT count(*)::int FROM ship_flight_recorder WHERE ship_id = :scout), 2, 'movement was recorded (spawn point plus one move)');

-- mining, the way tic.pl drives it
SET SESSION AUTHORIZATION t_alice;
UPDATE my_ships SET action = 'MINE', action_target_id = :home WHERE id = :miner;
SELECT fuel_reserve AS fuel_before FROM my_player \gset
SET SESSION AUTHORIZATION schemaverse;
SELECT is(mine(:miner, :home), true, 'mine() accepts a ship in range of its target');
SELECT is(perform_mining(), 1, 'perform_mining runs');
SELECT ok((SELECT fuel_reserve >= :fuel_before FROM player WHERE username = 't_alice'), 'fuel reserve did not go down');
SELECT ok((SELECT count(*) > 0 FROM event WHERE action IN ('MINE_SUCCESS', 'MINE_FAIL') AND ship_id_1 = :miner), 'a mining event was logged');

-- combat: bob's ship is teleported next to alice's scout by the owner
SET SESSION AUTHORIZATION t_bob;
INSERT INTO my_ships(name) VALUES ('target');
SELECT id AS target FROM my_ships \gset
SET SESSION AUTHORIZATION schemaverse;
UPDATE ship SET location = (SELECT location FROM ship WHERE id = :scout) WHERE id = :target;
SET SESSION AUTHORIZATION t_alice;
SELECT ok(attack(:scout, :target) > 0, 'attack in range does damage');
SELECT is(attack(:scout, :target), 0, 'a ship acts once per tic');
SET SESSION AUTHORIZATION schemaverse;
SELECT ok((SELECT future_health < 100 FROM ship WHERE id = :target), 'damage lands on future_health');
SELECT is((SELECT count(*)::int FROM event WHERE action = 'ATTACK' AND ship_id_1 = :scout AND ship_id_2 = :target), 1, 'ATTACK event is public');

SELECT * FROM finish();
ROLLBACK;
