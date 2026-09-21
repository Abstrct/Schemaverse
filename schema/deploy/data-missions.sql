-- Deploy data-missions
-- requires: table-mission
--
-- The first eleven missions. Each check is a boolean expression run as the
-- owner with $1 = player id, scoped to the current round.

BEGIN;

INSERT INTO mission (sort, code, title, description, hint, reward_balance, reward_fuel, check_sql) VALUES
(10, 'buy_ship', 'Commission a ship', 'Buy your first ship. It appears on one of your planets.',
 'INSERT INTO my_ships(name) VALUES (''Explorer'');', 500, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''BUY_SHIP'' AND player_id_1 = $1)'),
(20, 'name_ship', 'Name it', 'Give a ship a name. Ships are rows; UPDATE them.',
 'UPDATE my_ships SET name = ''Persephone'' WHERE id = 1;', 250, 0,
 'EXISTS (SELECT 1 FROM ship WHERE player_id = $1 AND NOT destroyed AND name IS NOT NULL AND name <> '''')'),
(30, 'mine', 'Strike fuel', 'Mine a planet. Set a ship''s action to MINE with a planet in range as the target, then wait a tic.',
 'UPDATE my_ships SET action = ''MINE'', action_target_id = (SELECT planet FROM planets_in_range WHERE ship = 1 LIMIT 1) WHERE id = 1;', 1000, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''MINE_SUCCESS'' AND player_id_1 = $1)'),
(40, 'move', 'Get moving', 'Set a course and let a tic pass. Ships burn fuel to change velocity.',
 'SELECT ship_course_control(1, 500, NULL, point(0, 0));', 500, 0,
 'EXISTS (SELECT 1 FROM ship_flight_recorder r JOIN ship s ON s.id = r.ship_id WHERE s.player_id = $1 GROUP BY r.ship_id HAVING count(*) >= 2)'),
(50, 'refuel', 'Top up', 'Refuel a ship from your reserve.',
 'SELECT refuel_ship(1);', 250, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''REFUEL_SHIP'' AND player_id_1 = $1)'),
(60, 'upgrade', 'Better, stronger', 'Upgrade a ship. Prices are in price_list.',
 'SELECT upgrade(1, ''PROSPECTING'', 5);', 500, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''UPGRADE_SHIP'' AND player_id_1 = $1)'),
(70, 'save_query', 'Keep a query', 'Save a query you want again. my_query_store is a table only you can see.',
 'INSERT INTO my_query_store(name, query_text) VALUES (''fleet'', ''SELECT * FROM my_ships'');', 250, 0,
 'EXISTS (SELECT 1 FROM my_query_store WHERE player_id = $1)'),
(80, 'explore', 'Far from home', 'Get a ship more than 100,000 units from any planet you own.',
 'SELECT ship_course_control(1, 1000, NULL, point(location[0] + 150000, location[1])) FROM my_ships WHERE id = 1;', 1000, 20000,
 'EXISTS (SELECT 1 FROM ship s WHERE s.player_id = $1 AND NOT s.destroyed AND NOT EXISTS (SELECT 1 FROM planet p WHERE p.conqueror_id = $1 AND (p.location <-> s.location) < 100000))'),
(90, 'automate', 'Let it fly itself', 'Write a fleet script, enable it, and have it complete a tic. Fleets are PL/pgSQL that runs as you.',
 'INSERT INTO my_fleets(name) VALUES (''auto''); UPDATE my_fleets SET script = ''PERFORM 1;'', enabled = true; SELECT upgrade(id, ''FLEET_RUNTIME'', 1) FROM my_fleets;', 2000, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''FLEET_SUCCESS'' AND player_id_1 = $1)'),
(100, 'first_blood', 'Open fire', 'Attack another player''s ship. It has to be within range of yours.',
 'UPDATE my_ships SET action = ''ATTACK'', action_target_id = (SELECT id FROM ships_in_range LIMIT 1) WHERE id = 1;', 1000, 0,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''ATTACK'' AND player_id_1 = $1)'),
(110, 'conquer', 'Take a planet', 'Out-mine everyone else on a planet you do not own and it becomes yours.',
 'Send a miner to a planet with no conqueror and mine it for a few tics.', 3000, 50000,
 'EXISTS (SELECT 1 FROM event WHERE round_id = current_round() AND action = ''CONQUER'' AND player_id_1 = $1) OR (SELECT count(*) FROM planet WHERE conqueror_id = $1) >= 2');

COMMIT;
