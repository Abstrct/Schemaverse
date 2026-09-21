-- Deploy rls-policies
--
-- Until now the only thing standing between a player and another player's
-- ships was that the base tables were closed and the my_* views were owned by
-- the game owner. That works, but it is not how anyone secures a database in
-- 2026, and it means "SELECT * FROM ship" teaches nothing but an error.
--
-- Row level security moves the rule onto the table. A player may now read
-- ship, ship_control, fleet, event, planet, player, variable and
-- ship_flight_recorder directly and sees exactly the rows the views used to
-- show. Writes are limited the same way, and the existing triggers still run.
-- The owner, and SECURITY DEFINER functions running as the owner, are exempt,
-- so the tic and the views that must see everyone (ships_in_range,
-- current_player_stats, online_players) are unchanged.
--
-- Column grants hide what the views hid: planet.fuel and planet.difficulty
-- stay secret.

BEGIN;

-- player: your own row
ALTER TABLE player ENABLE ROW LEVEL SECURITY;
CREATE POLICY player_self_select ON player FOR SELECT TO players USING (username = SESSION_USER);
CREATE POLICY player_self_update ON player FOR UPDATE TO players USING (username = SESSION_USER) WITH CHECK (username = SESSION_USER);
GRANT SELECT (id, username, created, balance, fuel_reserve, error_channel, starting_fleet, symbol, rgb) ON player TO players;
GRANT UPDATE (starting_fleet, symbol, rgb) ON player TO players;

-- ship: your own ships; buy through INSERT, rename/refleet/scuttle through UPDATE
ALTER TABLE ship ENABLE ROW LEVEL SECURITY;
CREATE POLICY ship_own_select ON ship FOR SELECT TO players USING (player_id = get_player_id(SESSION_USER));
CREATE POLICY ship_own_insert ON ship FOR INSERT TO players WITH CHECK (player_id = get_player_id(SESSION_USER));
CREATE POLICY ship_own_update ON ship FOR UPDATE TO players
	USING (player_id = get_player_id(SESSION_USER) AND NOT destroyed)
	WITH CHECK (player_id = get_player_id(SESSION_USER));
GRANT SELECT, INSERT ON ship TO players;
GRANT UPDATE (name, fleet_id, destroyed) ON ship TO players;

-- ship_control: the controls of your own ships
ALTER TABLE ship_control ENABLE ROW LEVEL SECURITY;
CREATE POLICY ship_control_own_select ON ship_control FOR SELECT TO players USING (player_id = get_player_id(SESSION_USER));
CREATE POLICY ship_control_own_update ON ship_control FOR UPDATE TO players
	USING (player_id = get_player_id(SESSION_USER)) WITH CHECK (player_id = get_player_id(SESSION_USER));
GRANT SELECT ON ship_control TO players;
GRANT UPDATE (target_speed, target_direction, destination_x, destination_y, destination, repair_priority, action, action_target_id) ON ship_control TO players;

-- fleet: your own fleets and scripts
ALTER TABLE fleet ENABLE ROW LEVEL SECURITY;
CREATE POLICY fleet_own_select ON fleet FOR SELECT TO players USING (player_id = get_player_id(SESSION_USER));
CREATE POLICY fleet_own_insert ON fleet FOR INSERT TO players WITH CHECK (player_id = get_player_id(SESSION_USER));
CREATE POLICY fleet_own_update ON fleet FOR UPDATE TO players
	USING (player_id = get_player_id(SESSION_USER)) WITH CHECK (player_id = get_player_id(SESSION_USER));
GRANT SELECT ON fleet TO players;
GRANT INSERT (player_id, name) ON fleet TO players;
GRANT UPDATE (name, script, script_declarations, enabled) ON fleet TO players;

-- event: what happened to you, plus everything public
ALTER TABLE event ENABLE ROW LEVEL SECURITY;
CREATE POLICY event_visible ON event FOR SELECT TO players
	USING (public OR player_id_1 = get_player_id(SESSION_USER) OR player_id_2 = get_player_id(SESSION_USER));
GRANT SELECT ON event TO players;

-- planet: everyone sees every planet, minus its fuel and difficulty; rename your own
ALTER TABLE planet ENABLE ROW LEVEL SECURITY;
CREATE POLICY planet_all_select ON planet FOR SELECT TO players USING (true);
CREATE POLICY planet_own_update ON planet FOR UPDATE TO players
	USING (conqueror_id = get_player_id(SESSION_USER) AND id <> 1)
	WITH CHECK (conqueror_id = get_player_id(SESSION_USER));
GRANT SELECT (id, name, mine_limit, location_x, location_y, conqueror_id, location) ON planet TO players;
GRANT UPDATE (name) ON planet TO players;

-- variable: public system settings plus your own variables
ALTER TABLE variable ENABLE ROW LEVEL SECURITY;
CREATE POLICY variable_select ON variable FOR SELECT TO players
	USING ((NOT private AND player_id = 0) OR player_id = get_player_id(SESSION_USER));
CREATE POLICY variable_own_insert ON variable FOR INSERT TO players WITH CHECK (player_id = get_player_id(SESSION_USER));
CREATE POLICY variable_own_update ON variable FOR UPDATE TO players
	USING (player_id = get_player_id(SESSION_USER)) WITH CHECK (player_id = get_player_id(SESSION_USER));
CREATE POLICY variable_own_delete ON variable FOR DELETE TO players USING (player_id = get_player_id(SESSION_USER));
GRANT SELECT, DELETE ON variable TO players;
GRANT INSERT (name, char_value, numeric_value, description, player_id) ON variable TO players;
GRANT UPDATE (numeric_value, char_value, description) ON variable TO players;

-- ship_flight_recorder: where your ships have been
ALTER TABLE ship_flight_recorder ENABLE ROW LEVEL SECURITY;
CREATE POLICY flight_recorder_own_select ON ship_flight_recorder FOR SELECT TO players USING (player_id = get_player_id(SESSION_USER));
GRANT SELECT ON ship_flight_recorder TO players;

COMMIT;
