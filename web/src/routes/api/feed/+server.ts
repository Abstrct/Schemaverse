import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals, url }) => {
	const limit = Math.min(Number(url.searchParams.get('limit') ?? 50), 200);
	const since = Number(url.searchParams.get('since') ?? 0);
	try {
		const r = await locals.session!.client.query(
			`SELECT id, tic, rtrim(action) AS action, public, player_id_1, player_id_2, ship_id_1, ship_id_2,
			        referencing_id, descriptor_numeric, descriptor_string, location, toc, read_event(id) AS text
			   FROM my_events WHERE id > $2 ORDER BY id DESC LIMIT $1`,
			[limit, since]
		);
		return json({ events: r.rows });
	} catch (e) {
		return fail(500, e);
	}
};
