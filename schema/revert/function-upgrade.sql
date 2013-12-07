-- Revert function-upgrade

BEGIN;

DROP FUNCTION upgrade(integer, character varying, integer);

COMMIT;
