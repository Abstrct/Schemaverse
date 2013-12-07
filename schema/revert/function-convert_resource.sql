-- Revert function-convert_resource

BEGIN;

DROP FUNCTION convert_resource(character varying, bigint);

COMMIT;
