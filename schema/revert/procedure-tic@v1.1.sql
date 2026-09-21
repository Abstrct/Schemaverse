-- Revert procedure-tic

BEGIN;

DROP PROCEDURE tic_close();
DROP PROCEDURE tic_open();
DROP FUNCTION tic_health(integer);
DROP FUNCTION tic_actions();

COMMIT;
