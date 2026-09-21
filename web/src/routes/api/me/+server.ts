import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals }) => {
	const s = locals.session!;
	try {
		const r = await s.client.query(`
			SELECT p.id, p.username, p.balance, p.fuel_reserve, p.symbol, p.rgb, p.created,
			       (SELECT last_value FROM tic_seq) AS tic, current_round() AS round,
			       (SELECT count(*) FROM my_ships) AS ships,
			       (SELECT count(*) FROM planets WHERE conqueror_id = p.id) AS planets,
			       (SELECT count(*) FROM my_fleets WHERE enabled) AS active_fleets
			  FROM my_player p`);
		return json({ ...r.rows[0], recent: s.recent.slice(-20) });
	} catch (e) {
		return fail(500, e);
	}
};
