import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { COOKIE, createSession } from '$lib/server/sessions';
import { USERNAME_RE } from '$lib/server/db';

export const POST: RequestHandler = async ({ request, cookies, url }) => {
	const { username, password } = await request.json();
	if (typeof username !== 'string' || !USERNAME_RE.test(username) || typeof password !== 'string') {
		return json({ error: { message: 'username or password is malformed' } }, { status: 400 });
	}
	try {
		const session = await createSession(username, password);
		cookies.set(COOKIE, session.id, {
			path: '/',
			httpOnly: true,
			sameSite: 'lax',
			secure: url.protocol === 'https:',
			maxAge: 60 * 60 * 24
		});
		return json({ username: session.username, id: session.playerId });
	} catch (e) {
		return json({ error: { message: 'login failed: ' + (e as Error).message } }, { status: 401 });
	}
};
