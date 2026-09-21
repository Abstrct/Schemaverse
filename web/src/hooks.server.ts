import type { Handle } from '@sveltejs/kit';
import { COOKIE, getSession } from '$lib/server/sessions';

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.session = getSession(event.cookies.get(COOKIE));
	if (event.url.pathname.startsWith('/api/') && !event.url.pathname.startsWith('/api/auth/') && !event.locals.session) {
		return new Response(JSON.stringify({ error: 'not logged in' }), {
			status: 401,
			headers: { 'content-type': 'application/json' }
		});
	}
	return resolve(event);
};
