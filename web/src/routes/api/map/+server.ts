import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals }) => {
	try {
		const r = await locals.session!.client.query('SELECT map_snapshot() AS snap');
		return json(r.rows[0].snap);
	} catch (e) {
		return fail(500, e);
	}
};
