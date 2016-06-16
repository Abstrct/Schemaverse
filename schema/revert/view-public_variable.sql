-- Revert view-public_variable

BEGIN;

DROP RULE public_variable_delete ON public_variable;

DROP RULE public_variable_insert ON public_variable;

DROP RULE public_variable_update ON public_variable;

DROP VIEW public_variable;

COMMIT;
