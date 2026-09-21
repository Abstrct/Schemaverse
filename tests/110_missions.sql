\i tests/_prelude.sql
SELECT plan(9);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
SELECT ok((SELECT count(*) >= 11 FROM my_missions), 'missions are listed');
SELECT is((SELECT count(*)::int FROM my_missions WHERE completed_tic IS NOT NULL), 0, 'none completed yet');
SELECT is((SELECT count(*)::int FROM check_missions()), 0, 'check_missions finds nothing to claim');
SELECT balance AS b0 FROM my_player \gset

INSERT INTO my_ships(name) VALUES ('Explorer');
SELECT is((SELECT string_agg(code, ',' ORDER BY code) FROM check_missions()), 'buy_ship,name_ship', 'buying a named ship completes two missions');
SELECT is((SELECT balance - :b0 FROM my_player)::int, -1000 + 500 + 250, 'rewards were paid');
SELECT is((SELECT count(*)::int FROM check_missions()), 0, 'a mission is claimed once per round');
SELECT is((SELECT count(*)::int FROM my_missions WHERE completed_tic IS NOT NULL), 2, 'my_missions shows them done');

SET SESSION AUTHORIZATION t_bob;
SELECT is((SELECT count(*)::int FROM check_missions()), 0, 'bob gets nothing for alice''s ship');
SET SESSION AUTHORIZATION schemaverse;
SELECT is((SELECT count(*)::int FROM event WHERE action = 'MISSION' AND player_id_1 = get_player_id('t_alice')), 2, 'MISSION events were logged');

SELECT * FROM finish();
ROLLBACK;
