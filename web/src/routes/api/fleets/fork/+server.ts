// Copy a shared fleet script into a new fleet of your own, as you. Two
// statements a player could type in psql, nothing more.
import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const POST: RequestHandler = async ({ locals, request }) => {
	const { id } = await request.json();
	const c = locals.session!.client;
	try {
		const src = await c.query('SELECT name FROM shared_fleets WHERE id = $1', [Number(id)]);
		if (!src.rowCount) return json({ error: { message: 'that fleet is not shared' } }, { status: 404 });
		await c.query('INSERT INTO my_fleets(name) VALUES ($1)', [String(src.rows[0].name || 'fleet').slice(0, 43) + ' (fork)']);
		const mine = await c.query('SELECT max(id) AS id FROM my_fleets');
		await c.query(
			`UPDATE my_fleets SET script = s.script, script_declarations = s.script_declarations FROM shared_fleets s WHERE s.id = $1 AND my_fleets.id = $2`,
			[Number(id), mine.rows[0].id]
		);
		return json({ id: mine.rows[0].id });
	} catch (e) {
		return fail(400, e);
	}
};
