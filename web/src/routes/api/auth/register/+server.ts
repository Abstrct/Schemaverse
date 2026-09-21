import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { COOKIE, createSession } from '$lib/server/sessions';
import { registrar, USERNAME_RE } from '$lib/server/db';
import { fail } from '$lib/server/respond';

export const POST: RequestHandler = async ({ request, cookies, url }) => {
	const { username, password } = await request.json();
	if (typeof username !== 'string' || !USERNAME_RE.test(username)) {
		return json({ error: { message: 'username must be 2-31 characters of a-z, 0-9 and _, starting with a letter' } }, { status: 400 });
	}
	if (typeof password !== 'string' || password.length < 8) {
		return json({ error: { message: 'password must be at least 8 characters' } }, { status: 400 });
	}
	let reg;
	try {
		reg = await registrar();
		await reg.query('SELECT register_player($1, $2)', [username, password]);
	} catch (e) {
		return fail(400, e);
	} finally {
		await reg?.end();
	}
	const session = await createSession(username, password);
	cookies.set(COOKIE, session.id, {
		path: '/',
		httpOnly: true,
		sameSite: 'lax',
		secure: url.protocol === 'https:',
		maxAge: 60 * 60 * 24
	});
	return json({ username: session.username, id: session.playerId, created: true });
};
