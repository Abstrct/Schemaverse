-- Verify role-players

BEGIN;

SELECT 1/count(*) FROM pg_roles WHERE rolname = 'players' AND NOT rolcanlogin;

ROLLBACK;
