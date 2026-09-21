-- Deploy data-gameplay_variables
-- requires: table-variable
--
-- Every gameplay lever from Phase 4 of the plan, as a public variable so an
-- instructor can read and tune them with plain SQL. All of them default to
-- the classic rules; apply_preset() switches sets of them at once.

BEGIN;

INSERT INTO variable (name, private, numeric_value, char_value, description, player_id) VALUES
	('SHIP_UPKEEP',              'f', 0,        '', 'Fuel each living ship costs its owner every tic, taken from fuel_reserve. When the reserve is empty the ship''s own tank pays instead. 0 disables.', 0),
	('UPGRADE_PRICE_SCALE',      'f', 0,        '', 'Progressive pricing: an upgrade costs base price * (1 + current stat value / this). 0 means flat prices.', 0),
	('SPAWN_MIN_DISTANCE',       'f', 0,        '', 'A new player''s home planet is placed at least this far from any planet held by a player with more ships than the median. 0 disables.', 0),
	('GRACE_TICS',               'f', 0,        '', 'For this many tics after joining (or after a round starts), a player''s ships within HOME_SAFE_RADIUS of one of their planets cannot be attacked. 0 disables.', 0),
	('HOME_SAFE_RADIUS',         'f', 5000,     '', 'Radius of the protected zone around a player''s planets during GRACE_TICS.', 0),
	('LATE_JOIN_STIPEND',        'f', 0,        '', 'Extra starting balance for a player who joins mid-round, scaled by how far the round has progressed (none at the start, all of it at the end).', 0),
	('LATE_JOIN_FUEL',           'f', 0,        '', 'Extra starting fuel reserve for a late joiner, scaled the same way.', 0),
	('PLANET_REGEN_PER_TIC',     'f', 1000000,  '', 'Fuel added each tic to every planet below PLANET_REGEN_CAP. Replaces the random top-up the old ticker did.', 0),
	('PLANET_REGEN_CAP',         'f', 10000000, '', 'Planets at or above this much fuel do not regenerate.', 0),
	('PLANET_REGEN_SMALL_BONUS', 'f', 0,        '', 'Percent extra regeneration for planets held by players with fewer ships than the median. 0 disables.', 0),
	('MISSION_CHECK_EVERY',      'f', 5,        '', 'tic_close() checks every player''s missions every this many tics. Players can also call check_missions() themselves.', 0)
ON CONFLICT (name, player_id) DO NOTHING;

COMMIT;
