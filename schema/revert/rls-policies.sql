-- Revert rls-policies

BEGIN;

REVOKE ALL ON player, ship, ship_control, fleet, event, planet, variable, ship_flight_recorder FROM players;

DROP POLICY player_self_select ON player;
DROP POLICY player_self_update ON player;
DROP POLICY ship_own_select ON ship;
DROP POLICY ship_own_insert ON ship;
DROP POLICY ship_own_update ON ship;
DROP POLICY ship_control_own_select ON ship_control;
DROP POLICY ship_control_own_update ON ship_control;
DROP POLICY fleet_own_select ON fleet;
DROP POLICY fleet_own_insert ON fleet;
DROP POLICY fleet_own_update ON fleet;
DROP POLICY event_visible ON event;
DROP POLICY planet_all_select ON planet;
DROP POLICY planet_own_update ON planet;
DROP POLICY variable_select ON variable;
DROP POLICY variable_own_insert ON variable;
DROP POLICY variable_own_update ON variable;
DROP POLICY variable_own_delete ON variable;
DROP POLICY flight_recorder_own_select ON ship_flight_recorder;

ALTER TABLE player DISABLE ROW LEVEL SECURITY;
ALTER TABLE ship DISABLE ROW LEVEL SECURITY;
ALTER TABLE ship_control DISABLE ROW LEVEL SECURITY;
ALTER TABLE fleet DISABLE ROW LEVEL SECURITY;
ALTER TABLE event DISABLE ROW LEVEL SECURITY;
ALTER TABLE planet DISABLE ROW LEVEL SECURITY;
ALTER TABLE variable DISABLE ROW LEVEL SECURITY;
ALTER TABLE ship_flight_recorder DISABLE ROW LEVEL SECURITY;

COMMIT;
