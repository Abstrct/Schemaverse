\i tests/_prelude.sql
SELECT plan(13);
SELECT register_player('t_alice', 'password-one');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
GRANT ALL ON ALL SEQUENCES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
SELECT is((SELECT balance FROM my_player)::int, 10000, 'starting balance is 10000');
SELECT lives_ok($$INSERT INTO my_ships(name) VALUES ('s1')$$, 'a ship without a location spawns at home');
SELECT is((SELECT count(*)::int FROM my_ships), 1, 'one ship');
SELECT is((SELECT balance FROM my_player)::int, 9000, 'charged the SHIP price');
SELECT ok((SELECT s.location ~= p.location FROM my_ships s, planets p WHERE p.conqueror_id = get_player_id('t_alice')), 'ship sits on the home planet');

INSERT INTO my_ships(name, location) VALUES ('bad', point(1, 1));
SELECT is((SELECT count(*)::int FROM my_ships), 1, 'a ship placed off any owned planet is rejected');
INSERT INTO my_ships(name, attack) VALUES ('strong', 6);
SELECT is((SELECT count(*)::int FROM my_ships), 1, 'skill total above 20 is rejected');
INSERT INTO my_ships(name, attack) VALUES ('neg', -1);
SELECT is((SELECT count(*)::int FROM my_ships), 1, 'negative skill is rejected');
INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('max', 20, 0, 0, 0);
SELECT is((SELECT count(*)::int FROM my_ships), 2, 'a 20/0/0/0 ship is allowed');

SET SESSION AUTHORIZATION schemaverse;
UPDATE variable SET numeric_value = 2 WHERE name = 'MAX_SHIPS';
SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('third');
SELECT is((SELECT count(*)::int FROM my_ships), 2, 'MAX_SHIPS variable is honoured');

DELETE FROM my_ships WHERE name = 'max';
SELECT is((SELECT count(*)::int FROM my_ships), 1, 'DELETE on my_ships scuttles the ship');
SELECT is((SELECT balance FROM my_player)::int, 9000, 'scuttling refunds the ship price');

SET SESSION AUTHORIZATION schemaverse;
SELECT is((SELECT count(*)::int FROM event WHERE action = 'EXPLODE' AND player_id_1 = get_player_id('t_alice')), 1, 'an EXPLODE event was logged');

SELECT * FROM finish();
ROLLBACK;
