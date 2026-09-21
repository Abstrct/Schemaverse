\i tests/_prelude.sql
-- tic_health() is the settle-health phase of tic_close(), factored out so it
-- can be tested inside a transaction.
SELECT plan(9);
SELECT register_player('t_alice', 'password-one');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('hurt'), ('overhealed'), ('dying'), ('dead');
SET SESSION AUTHORIZATION schemaverse;
SELECT last_value AS tic FROM tic_seq \gset

UPDATE ship SET future_health = 40  WHERE name = 'hurt';
UPDATE ship SET future_health = 150 WHERE name = 'overhealed';
UPDATE ship SET future_health = -5, last_living_tic = :tic - 1 WHERE name = 'dying';
UPDATE ship SET future_health = 0, current_health = 0, last_living_tic = :tic - 10 WHERE name = 'dead';

SELECT is(tic_health(:tic), 1, 'one ship destroyed this tic');
SELECT is((SELECT current_health FROM ship WHERE name = 'hurt'), 40, 'damage shows immediately');
SELECT is((SELECT current_health FROM ship WHERE name = 'overhealed'), 100, 'health is capped at max_health');
SELECT is((SELECT future_health FROM ship WHERE name = 'overhealed'), 100, 'repairs do not bank above max_health');
SELECT is((SELECT current_health FROM ship WHERE name = 'dying'), 0, 'health floors at zero');
SELECT is((SELECT last_living_tic FROM ship WHERE name = 'dying'), :tic - 1, 'a ship at zero keeps its last living tic');
SELECT is((SELECT last_living_tic FROM ship WHERE name = 'hurt'), :tic, 'a living ship is stamped with the tic');
SELECT is((SELECT destroyed FROM ship WHERE name = 'dead'), true, 'a ship dead past EXPLODED tics is destroyed');
SELECT is((SELECT count(*)::int FROM event WHERE action = 'EXPLODE' AND player_id_1 = get_player_id('t_alice')), 1, 'destroy_ship logged the explosion');

SELECT * FROM finish();
ROLLBACK;
