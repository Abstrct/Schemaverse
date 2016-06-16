-- Revert function-ship_course_control

BEGIN;

DROP FUNCTION scc(integer, integer, integer, integer, integer);
DROP FUNCTION ship_course_control(integer, integer, integer, integer, integer);
DROP FUNCTION ship_course_control(integer, integer, integer, point);

COMMIT;
