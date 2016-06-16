-- Revert function-action_permission_check

BEGIN;

DROP FUNCTION action_permission_check(integer);

COMMIT;
