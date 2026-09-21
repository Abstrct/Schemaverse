-- Revert function-charge_scaled

BEGIN;

DROP FUNCTION charge(character varying, bigint, numeric);

COMMIT;
