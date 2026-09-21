-- Revert function-attack

BEGIN;

DROP FUNCTION attack(integer, integer);

COMMIT;
