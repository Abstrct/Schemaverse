-- Verify function-ship_course_control

BEGIN;

SELECT 1/count(*) FROM pg_proc WHERE proname = 'ship_course_control';

ROLLBACK;
