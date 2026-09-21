\i tests/_prelude.sql
SELECT plan(8);
SELECT register_player('t_alice', 'password-one');
SELECT register_player('t_bob', 'password-two');
GRANT ALL ON ALL TABLES IN SCHEMA :"tmpns" TO players;
GRANT ALL ON ALL SEQUENCES IN SCHEMA :"tmpns" TO players;

SET SESSION AUTHORIZATION t_alice;
INSERT INTO my_fleets(name) VALUES ('good');
INSERT INTO my_fleets(name) VALUES ('evil');
SELECT id AS good FROM my_fleets WHERE name = 'good' \gset
SELECT id AS evil FROM my_fleets WHERE name = 'evil' \gset

UPDATE my_fleets SET script_declarations = 'n integer;', script = 'n := 1;' WHERE id = :good;
SET SESSION AUTHORIZATION schemaverse;  -- players cannot read pg_proc
SELECT is((SELECT count(*)::int FROM pg_proc WHERE proname = 'fleet_script_' || :good), 1, 'saving a script compiles a fleet_script_N function');
SET SESSION AUTHORIZATION t_alice;
SELECT lives_ok('SELECT fleet_script_' || :good || '()', 'the owner can run it');
SELECT lives_ok('SELECT run_fleet_script(' || :good || ')', 'run_fleet_script wraps it');
SET SESSION AUTHORIZATION schemaverse;  -- my_events hides the current tic until it completes
SELECT is((SELECT count(*)::int FROM event WHERE action = 'FLEET_SUCCESS' AND referencing_id = :good), 1, 'FLEET_SUCCESS event logged');
SET SESSION AUTHORIZATION t_alice;

-- Try to close the dollar quote and define a function outside the script body.
SELECT throws_ok(
  $$UPDATE my_fleets SET script = 'RETURN 1; END $fs_00000000000000000000000000000000$ LANGUAGE plpgsql; CREATE FUNCTION public.evil() RETURNS int AS $x$ SELECT 1 $x$ LANGUAGE sql; --' WHERE id = $$ || :evil,
  '42601', NULL, 'a script that tries to escape its dollar quote fails to compile');
SET SESSION AUTHORIZATION schemaverse;
SELECT is((SELECT count(*)::int FROM pg_proc WHERE proname = 'evil'), 0, 'no function escaped the sandbox');

SET SESSION AUTHORIZATION t_bob;
SELECT throws_like('SELECT fleet_script_' || :good || '()', '%permission denied%', 'another player cannot execute it');
SELECT is((SELECT count(*)::int FROM my_fleets), 0, 'another player cannot see it');

SET SESSION AUTHORIZATION schemaverse;
SELECT * FROM finish();
ROLLBACK;
