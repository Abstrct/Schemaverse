-- Verify function-register_player

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'register_player' AND prosecdef;
SELECT 1/count(*) FROM pg_roles WHERE rolname = 'registrar';
SELECT 1/(CASE WHEN has_function_privilege('registrar', 'register_player(text,text)', 'EXECUTE') THEN 1 ELSE 0 END);
SELECT 1/(CASE WHEN has_function_privilege('players', 'register_player(text,text)', 'EXECUTE') THEN 0 ELSE 1 END);

ROLLBACK;
