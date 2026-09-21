\i tests/_prelude.sql
SELECT plan(11);
SELECT register_player('t_alice', 'password-one');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_ships(name) VALUES ('doomed');
SET SESSION AUTHORIZATION schemaverse;

SELECT last_value AS round_before FROM round_seq \gset
UPDATE variable SET char_value = '2000-01-01' WHERE name = 'ROUND_START_DATE';
SELECT is(round_control(), true, 'round_control runs when the round has expired');
SELECT is((SELECT count(*)::int FROM ship), 0, 'ships are gone');
SELECT is((SELECT count(*)::int FROM event WHERE round_id = current_round()), 0, 'the new round starts with no events');
SELECT ok((SELECT count(*) > 0 FROM event WHERE round_id = :round_before), 'the old round''s events are kept');
SELECT ok((SELECT count(*) > 0 FROM event_archive WHERE round_id = :round_before AND action = 'BUY_SHIP'), 'event_archive shows them');
SELECT ok(to_regclass('event_round_' || current_round()) IS NOT NULL, 'a partition exists for the new round');
SELECT ok((SELECT count(*) >= (SELECT count(*) FROM player) * 1.05 FROM planet), 'a fresh universe was generated');
SELECT is((SELECT count(*)::int FROM planet WHERE conqueror_id = get_player_id('t_alice')), 1, 'every player got a home planet');
SELECT is((SELECT balance FROM player WHERE username = 't_alice')::int, 10000, 'balances reset');
SELECT is((SELECT last_value FROM round_seq)::int, :round_before + 1, 'round advanced');
SELECT is((SELECT char_value FROM variable WHERE name = 'ROUND_START_DATE')::text, current_date::text, 'round start date is today');

SELECT * FROM finish();
-- nextval() is not transactional: put the round back where it was before ROLLBACK
SELECT setval('round_seq', :round_before, true);
ROLLBACK;
