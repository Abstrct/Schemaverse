// The console. Runs whatever the player sends, as the player, on the player's
// own connection. Multiple statements are allowed (simple protocol). Results
// are capped so a SELECT * FROM event does not take the browser down.
import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';
import type pg from 'pg';

const MAX_ROWS = 2000;

export const POST: RequestHandler = async ({ request, locals }) => {
	const s = locals.session!;
	const { sql } = await request.json();
	if (typeof sql !== 'string' || !sql.trim()) return json({ error: { message: 'empty query' } }, { status: 400 });
	const started = performance.now();
	try {
		const raw = await s.client.query({ text: sql, rowMode: 'array' });
		const results = (Array.isArray(raw) ? raw : [raw]).map((r: pg.QueryArrayResult) => ({
			command: r.command,
			rowCount: r.rowCount,
			fields: (r.fields ?? []).map((f) => ({ name: f.name, type: f.dataTypeID })),
			rows: (r.rows ?? []).slice(0, MAX_ROWS),
			truncated: (r.rows?.length ?? 0) > MAX_ROWS
		}));
		return json({ results, ms: Math.round(performance.now() - started) });
	} catch (e) {
		return fail(400, e);
	}
};
