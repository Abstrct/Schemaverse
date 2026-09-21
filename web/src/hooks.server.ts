import type { Handle } from '@sveltejs/kit';
import { COOKIE, getSession } from '$lib/server/sessions';

// Nothing under /play or /api is for crawlers: both need a session.
const gated = (pathname: string) => pathname.startsWith('/play') || pathname.startsWith('/api');

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.session = getSession(event.cookies.get(COOKIE));
	if (event.url.pathname.startsWith('/api/') && !event.url.pathname.startsWith('/api/auth/') && !event.locals.session) {
		return new Response(JSON.stringify({ error: 'not logged in' }), {
			status: 401,
			headers: { 'content-type': 'application/json', 'x-robots-tag': 'noindex, nofollow' }
		});
	}
	const response = await resolve(event);
	if (gated(event.url.pathname)) response.headers.set('x-robots-tag', 'noindex, nofollow');
	return response;
};
