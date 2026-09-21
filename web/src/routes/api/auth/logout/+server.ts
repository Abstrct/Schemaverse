import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { COOKIE, destroySession } from '$lib/server/sessions';

export const POST: RequestHandler = async ({ cookies, locals }) => {
	if (locals.session) await destroySession(locals.session.id);
	cookies.delete(COOKIE, { path: '/' });
	return json({ ok: true });
};
