-- Revert view-planets

BEGIN;

DROP RULE planet_update ON planets;
DROP VIEW planets;

COMMIT;
