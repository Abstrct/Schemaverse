-- Revert table-mission

BEGIN;

DROP FUNCTION check_all_missions();
DROP FUNCTION check_missions(integer);
DROP VIEW my_missions;
DELETE FROM event WHERE action = 'MISSION';
DELETE FROM action WHERE name = 'MISSION';
DROP TABLE mission_progress;
DROP TABLE mission;

COMMIT;
