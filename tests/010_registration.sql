\i tests/_prelude.sql
SELECT plan(11);

SELECT lives_ok($$SELECT register_player('t_alice', 'password-one')$$, 'register_player creates a player');
SELECT is((SELECT count(*)::int FROM pg_roles WHERE rolname = 't_alice'), 1, 'a login role exists');
RESET SESSION AUTHORIZATION;  -- pg_authid is superuser-only
SELECT ok((SELECT rolpassword LIKE 'SCRAM-SHA-256$%' FROM pg_authid WHERE rolname = 't_alice'), 'password stored as SCRAM, hashed by the server');
SET SESSION AUTHORIZATION schemaverse;
SELECT ok(pg_has_role('t_alice', 'players', 'MEMBER'), 'member of the players group');
SELECT is((SELECT count(*)::int FROM planet WHERE conqueror_id = get_player_id('t_alice')), 1, 'home planet assigned');
SELECT is((SELECT count(*)::int FROM player_round_stats WHERE player_id = get_player_id('t_alice')), 1, 'round stats row created');
SELECT throws_like($$SELECT register_player('t_alice', 'password-two')$$, '%is taken%', 'duplicate username rejected');
SELECT throws_like($$SELECT register_player('Robert''; DROP TABLE player;--', 'password-two')$$, '%username must be%', 'username with SQL in it rejected');
SELECT throws_like($$SELECT register_player('t_bob', 'short')$$, '%at least 8%', 'short password rejected');
SELECT throws_like($$SELECT register_player('schemaverse', 'password-two')$$, '%is taken%', 'reserved name rejected');
SELECT is((SELECT count(*)::int FROM information_schema.columns WHERE table_name = 'player' AND column_name = 'password'), 0, 'player table has no password column');

SELECT * FROM finish();
ROLLBACK;
