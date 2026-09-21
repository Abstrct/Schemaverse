\i tests/_prelude.sql
-- map_snapshot() is SECURITY INVOKER over the player views, so it can show a
-- player exactly what psql would and nothing more.
SELECT plan(10);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('a1');
SELECT id AS a1 FROM my_ships \gset
SET SESSION AUTHORIZATION t_bob;
INSERT INTO my_ships(name) VALUES ('b1');
SELECT id AS b1 FROM my_ships \gset

SET SESSION AUTHORIZATION t_alice;
SELECT map_snapshot() AS snap \gset
SELECT is((:'snap'::jsonb->'me'->>'username'), 't_alice', 'me is the caller');
SELECT is((:'snap'::jsonb->>'round')::int, current_round(), 'round is reported');
SELECT is(jsonb_array_length(:'snap'::jsonb->'ships'), 1, 'one own ship');
SELECT is((:'snap'::jsonb->'ships'->0->>'id')::int, :a1, 'and it is a1');
SELECT ok(jsonb_array_length(:'snap'::jsonb->'planets') > 0, 'planets are listed');
SELECT ok((SELECT bool_and(p ? 'conqueror') FROM jsonb_array_elements(:'snap'::jsonb->'planets') p), 'each planet carries a conqueror badge (or null)');
SELECT is(jsonb_array_length(:'snap'::jsonb->'contacts'), 0, 'bob''s ship is out of range, so no contacts');
SELECT ok((:'snap'::jsonb->'bounds'->>'max_x')::float > (:'snap'::jsonb->'bounds'->>'min_x')::float, 'map bounds are reported');

-- teleport bob's ship next to alice's, as the owner
SET SESSION AUTHORIZATION schemaverse;
UPDATE ship SET location = (SELECT location FROM ship WHERE id = :a1) WHERE id = :b1;
SET SESSION AUTHORIZATION t_alice;
SELECT map_snapshot() AS snap2 \gset
SELECT is(jsonb_array_length(:'snap2'::jsonb->'contacts'), 1, 'now bob''s ship is a contact');
SELECT is((:'snap2'::jsonb->'contacts'->0->'player'->>'username'), 't_bob', 'labelled with bob''s badge');

SET SESSION AUTHORIZATION schemaverse;
SELECT * FROM finish();
ROLLBACK;
