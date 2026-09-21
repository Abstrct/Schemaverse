-- Deploy function-map_snapshot
-- requires: function-player_badge
-- requires: view-my_ships
-- requires: view-ships_in_range
-- requires: view-planets
-- requires: view-my_player
--
-- One document with everything the calling player is allowed to see on the
-- map right now. It is SECURITY INVOKER on purpose: it reads the same views a
-- psql player reads, so it cannot leak more than psql would. The web map calls
-- it on every 'tic' NOTIFY.
--
--   tic, round             where the clock is
--   bounds                 min/max x and y over all planets (the map extent)
--   me                     id, username, symbol, rgb, balance, fuel_reserve
--   planets[]              every planet, with the conqueror's badge
--   ships[]                your ships, with controls and stats
--   contacts[]             other players' ships inside one of your ships' range

BEGIN;

CREATE OR REPLACE FUNCTION map_snapshot() RETURNS jsonb AS
$$
	SELECT jsonb_build_object(
		'tic',      (SELECT last_value FROM public.tic_seq),
		'round',    public.current_round(),
		'bounds',   (SELECT jsonb_build_object('min_x', min(location[0]), 'max_x', max(location[0]),
		                                       'min_y', min(location[1]), 'max_y', max(location[1]))
		               FROM public.planets),
		'me',       (SELECT jsonb_build_object('id', id, 'username', username, 'symbol', symbol, 'rgb', rgb,
		                                       'balance', balance, 'fuel_reserve', fuel_reserve)
		               FROM public.my_player),
		'planets',  (SELECT coalesce(jsonb_agg(jsonb_build_object(
		                 'id', p.id, 'name', p.name, 'x', p.location[0], 'y', p.location[1],
		                 'mine_limit', p.mine_limit, 'conqueror_id', p.conqueror_id,
		                 'conqueror', CASE WHEN p.conqueror_id IS NULL THEN NULL ELSE public.player_badge(p.conqueror_id) END)
		               ORDER BY p.id), '[]'::jsonb)
		               FROM public.planets p),
		'ships',    (SELECT coalesce(jsonb_agg(jsonb_build_object(
		                 'id', s.id, 'name', s.name, 'fleet_id', s.fleet_id,
		                 'x', s.location[0], 'y', s.location[1],
		                 'direction', s.direction, 'speed', s.speed,
		                 'target_speed', s.target_speed, 'target_direction', s.target_direction,
		                 'destination_x', s.destination[0], 'destination_y', s.destination[1],
		                 'current_health', s.current_health, 'max_health', s.max_health,
		                 'current_fuel', s.current_fuel, 'max_fuel', s.max_fuel,
		                 'max_speed', s.max_speed, 'range', s.range,
		                 'attack', s.attack, 'defense', s.defense, 'engineering', s.engineering, 'prospecting', s.prospecting,
		                 'action', rtrim(s.action), 'action_target_id', s.action_target_id,
		                 'last_action_tic', s.last_action_tic)
		               ORDER BY s.id), '[]'::jsonb)
		               FROM public.my_ships s),
		'contacts', (SELECT coalesce(jsonb_agg(DISTINCT jsonb_build_object(
		                 'id', r.id, 'name', r.name, 'player_id', r.player_id,
		                 'x', r.enemy_location[0], 'y', r.enemy_location[1],
		                 'health', r.health, 'player', public.player_badge(r.player_id))), '[]'::jsonb)
		               FROM public.ships_in_range r)
	)
$$ LANGUAGE sql STABLE;

GRANT EXECUTE ON FUNCTION map_snapshot() TO players;

COMMIT;
