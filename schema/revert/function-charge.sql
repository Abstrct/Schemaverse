-- Revert function-charge

BEGIN;

DROP FUNCTION charge(character varying, bigint);

COMMIT;
