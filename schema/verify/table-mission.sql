-- Verify table-mission

BEGIN;

SELECT 1/count(*) FROM pg_tables WHERE tablename = 'mission';
SELECT 1/count(*) FROM pg_tables WHERE tablename = 'mission_progress' AND rowsecurity;
SELECT 1/count(*) FROM pg_views WHERE viewname = 'my_missions';
SELECT 1/count(*) FROM pg_proc WHERE proname = 'check_missions' AND prosecdef;
SELECT 1/count(*) FROM action WHERE name = 'MISSION';

ROLLBACK;
