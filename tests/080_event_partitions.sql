\i tests/_prelude.sql
-- The event table is partitioned by round. Players see the current round in
-- my_events and earlier rounds in event_archive, both under RLS.
SELECT plan(10);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;

SELECT ok((SELECT relkind = 'p' FROM pg_class WHERE relname = 'event'), 'event is a partitioned table');
SELECT ok(to_regclass('event_round_' || current_round()) IS NOT NULL, 'the current round has a partition');
SELECT is((SELECT attidentity FROM pg_attribute WHERE attrelid = 'event'::regclass AND attname = 'id'), 'a', 'event.id is an identity column');

-- self-healing: a round whose partition is missing gets one, with its strays
SELECT is(ensure_event_partition(current_round()), false, 'ensure_event_partition is a no-op when the partition exists');
INSERT INTO event(action, player_id_1, round_id, tic, public) VALUES ('TIC', 0, 99, 1, true);
SELECT is(ensure_event_partition(99), true, 'a missing partition is created');
SELECT is((SELECT count(*)::int FROM event_round_99), 1, 'and the stray row moved into it from event_default');
INSERT INTO event(action, player_id_1, tic, public) VALUES ('TIC', 0, 1, true);
SELECT is((SELECT round_id FROM event WHERE action = 'TIC' ORDER BY id DESC LIMIT 1), current_round(), 'new events land in the current round');

SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('s');
SELECT is((SELECT count(*)::int FROM event WHERE action = 'BUY_SHIP'), 1, 'alice sees her own BUY_SHIP through RLS on the partitioned table');
SELECT is((SELECT count(*)::int FROM event_archive), 0, 'nothing in the archive during round one');
SET SESSION AUTHORIZATION t_bob;
SELECT is((SELECT count(*)::int FROM event WHERE action = 'BUY_SHIP'), 0, 'bob does not see it');

SET SESSION AUTHORIZATION schemaverse;
SELECT * FROM finish();
ROLLBACK;
