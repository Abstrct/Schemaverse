\i tests/_prelude.sql
-- The Phase 4 levers. Variables are changed inside the test transaction and
-- rolled back with it.
SELECT plan(15);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;

-- progressive pricing
SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('a', 20, 0, 0, 0);
SELECT id AS a FROM my_ships \gset
SET SESSION AUTHORIZATION schemaverse;
UPDATE variable SET numeric_value = 0 WHERE name = 'UPGRADE_PRICE_SCALE';
SET SESSION AUTHORIZATION t_alice;
SELECT balance AS b0 FROM my_player \gset
SELECT upgrade(:a, 'ATTACK', 1);
SELECT is((SELECT :b0 - balance FROM my_player)::int, 25, 'flat price: ATTACK +1 costs 25');
SET SESSION AUTHORIZATION schemaverse;
UPDATE variable SET numeric_value = 20 WHERE name = 'UPGRADE_PRICE_SCALE';  -- skill total is 21 now
SET SESSION AUTHORIZATION t_alice;
SELECT balance AS b1 FROM my_player \gset
SELECT upgrade(:a, 'ATTACK', 1);
SELECT is((SELECT :b1 - balance FROM my_player)::int, ceil(25 * (1 + 21 / 20.0))::int, 'progressive price scales with the current skill total');

-- grace period
SET SESSION AUTHORIZATION t_bob;
INSERT INTO my_ships(name, attack, defense, engineering, prospecting) VALUES ('b', 20, 0, 0, 0);
SELECT id AS b FROM my_ships \gset
SET SESSION AUTHORIZATION schemaverse;
UPDATE ship SET location = (SELECT location FROM ship WHERE id = :a) WHERE id = :b;  -- bob parks on alice's home planet
UPDATE variable SET numeric_value = 100 WHERE name = 'GRACE_TICS';
UPDATE ship SET last_action_tic = 0 WHERE id = :b;
SET SESSION AUTHORIZATION t_bob;
SELECT is(attack(:b, :a), 0, 'a new player''s ship at home cannot be attacked during the grace period');
SET SESSION AUTHORIZATION schemaverse;
UPDATE player SET joined_tic = -1000 WHERE username = 't_alice';  -- alice joined long ago
UPDATE ship SET last_action_tic = 0 WHERE id = :b;
SET SESSION AUTHORIZATION t_bob;
SELECT ok(attack(:b, :a) > 0, 'once the grace period is over the attack lands');
SET SESSION AUTHORIZATION schemaverse;
UPDATE variable SET numeric_value = 0 WHERE name = 'GRACE_TICS';

-- late-join stipend
UPDATE variable SET char_value = (current_date - 2)::text WHERE name = 'ROUND_START_DATE';
UPDATE variable SET char_value = '4 days' WHERE name = 'ROUND_LENGTH';  -- 2 days and change into 4: progress 0.5 .. 0.75
UPDATE variable SET numeric_value = 10000 WHERE name = 'LATE_JOIN_STIPEND';
UPDATE variable SET numeric_value = 100000 WHERE name = 'LATE_JOIN_FUEL';
SELECT register_player('t_carol', 'password-333');
SELECT ok((SELECT balance BETWEEN 15000 AND 17500 FROM player WHERE username = 't_carol'), 'past the middle of the round, a late joiner gets that share of the stipend');
SELECT ok((SELECT fuel_reserve BETWEEN 150000 AND 175000 FROM player WHERE username = 't_carol'), 'and the same share of the fuel');
SELECT is((SELECT joined_tic FROM player WHERE username = 't_carol'), current_tic(), 'joined_tic is stamped');

-- economy: regeneration and upkeep
UPDATE variable SET numeric_value = 1000 WHERE name = 'PLANET_REGEN_PER_TIC';
UPDATE variable SET numeric_value = 5000 WHERE name = 'PLANET_REGEN_CAP';
UPDATE planet SET fuel = 100 WHERE id = (SELECT id FROM planet WHERE conqueror_id = get_player_id('t_alice'));
UPDATE planet SET fuel = 4900 WHERE id = (SELECT id FROM planet WHERE conqueror_id = get_player_id('t_bob'));
UPDATE variable SET numeric_value = 0 WHERE name = 'SHIP_UPKEEP';
SELECT tic_economy(current_tic());
SELECT is((SELECT fuel FROM planet WHERE conqueror_id = get_player_id('t_alice')), 1100, 'a planet below the cap regenerates');
SELECT is((SELECT fuel FROM planet WHERE conqueror_id = get_player_id('t_bob')), 5000, 'regeneration stops at the cap');

UPDATE variable SET numeric_value = 40 WHERE name = 'SHIP_UPKEEP';
UPDATE player SET fuel_reserve = 100 WHERE username = 't_alice';  -- one ship, upkeep 40: pays from reserve
UPDATE player SET fuel_reserve = 10 WHERE username = 't_bob';     -- cannot pay: the ship's tank pays
UPDATE ship SET current_fuel = 100 WHERE id IN (:a, :b);
SELECT tic_economy(current_tic());
SELECT is((SELECT fuel_reserve FROM player WHERE username = 't_alice')::int, 60, 'upkeep comes out of the reserve');
SELECT is((SELECT current_fuel FROM ship WHERE id = :a), 100, 'and leaves the tank alone when the reserve covers it');
SELECT is((SELECT fuel_reserve FROM player WHERE username = 't_bob')::int, 0, 'an empty reserve floors at zero');
SELECT is((SELECT current_fuel FROM ship WHERE id = :b), 60, 'and the shortfall drains the tank');

-- presets
SELECT matches(apply_preset('classroom'), '^preset classroom applied', 'apply_preset works for the owner');
SELECT is((SELECT char_value FROM variable WHERE name = 'ROUND_LENGTH')::text, '1 hours', 'classroom rounds are an hour');

SELECT * FROM finish();
ROLLBACK;
