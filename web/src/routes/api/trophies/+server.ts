import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals }) => {
	try {
		const r = await locals.session!.client.query(`
			SELECT t.id, t.name, t.description, t.weight, t.approved,
			       (SELECT count(*) FROM player_trophy pt WHERE pt.trophy_id = t.id AND pt.player_id = get_player_id(SESSION_USER)) AS mine,
			       (SELECT count(*) FROM player_trophy pt WHERE pt.trophy_id = t.id) AS awarded
			  FROM trophy t ORDER BY t.weight DESC, t.name`);
		return json({ trophies: r.rows });
	} catch (e) {
		return fail(500, e);
	}
};
