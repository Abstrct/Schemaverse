-- Verify player-drop_password

BEGIN;

SELECT 1/(CASE WHEN count(*) = 0 THEN 1 ELSE 0 END) FROM information_schema.columns WHERE table_name = 'player' AND column_name = 'password';

ROLLBACK;
