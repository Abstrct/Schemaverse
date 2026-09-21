// Round replay data, as the player: every recorded position of your own ships
// (my_ships_flight_recorder) and your events, for a window of tics. Row level
// security keeps it to what psql would show you.
import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals, url }) => {
	const c = locals.session!.client;
	const from = Number(url.searchParams.get('from') ?? 0);
	const to = Number(url.searchParams.get('to') ?? 1e9);
	try {
		const meta = await c.query(`SELECT (SELECT last_value FROM tic_seq) AS tic, current_round() AS round,
			(SELECT min(tic) FROM my_ships_flight_recorder) AS first_tic, (SELECT max(tic) FROM my_ships_flight_recorder) AS last_tic`);
		const track = await c.query(
			`SELECT r.ship_id, r.tic, r.location[0] AS x, r.location[1] AS y, s.name
			   FROM my_ships_flight_recorder r LEFT JOIN my_ships s ON s.id = r.ship_id
			  WHERE r.tic BETWEEN $1 AND $2 ORDER BY r.tic, r.ship_id`, [from, to]);
		const events = await c.query(
			`SELECT id, tic, rtrim(action) AS action, ship_id_1, ship_id_2, player_id_1, player_id_2, descriptor_numeric, descriptor_string,
			        location[0] AS x, location[1] AS y, read_event(id) AS text
			   FROM my_events WHERE tic BETWEEN $1 AND $2 ORDER BY tic, id LIMIT 5000`, [from, to]);
		const planets = await c.query(`SELECT id, name, location[0] AS x, location[1] AS y, mine_limit, conqueror_id FROM planets ORDER BY id`);
		return json({ ...meta.rows[0], track: track.rows, events: events.rows, planets: planets.rows });
	} catch (e) {
		return fail(500, e);
	}
};
