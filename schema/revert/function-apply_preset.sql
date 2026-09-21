-- Revert function-apply_preset

BEGIN;

DROP FUNCTION apply_preset(text);

COMMIT;
