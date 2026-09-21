import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals }) => {
	try {
		const r = await locals.session!.client.query('SELECT * FROM my_missions');
		return json({ missions: r.rows });
	} catch (e) {
		return fail(500, e);
	}
};

/** Claim whatever the player has now met. Returns the missions completed by this call. */
export const POST: RequestHandler = async ({ locals }) => {
	try {
		const r = await locals.session!.client.query('SELECT id, code, title, reward_balance, reward_fuel FROM check_missions()');
		return json({ completed: r.rows });
	} catch (e) {
		return fail(500, e);
	}
};
