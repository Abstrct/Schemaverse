-- Revert view-my_fleets

BEGIN;


DROP RULE fleet_insert ON my_fleets;
DROP RULE fleet_update ON my_fleets;

DROP VIEW my_fleets;


COMMIT;
