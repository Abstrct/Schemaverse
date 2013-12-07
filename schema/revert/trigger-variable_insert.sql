-- Revert trigger-variable_insert

BEGIN;


DROP TRIGGER VARIABLE_INSERT ON variable;

DROP FUNCTION variable_insert();

COMMIT;
