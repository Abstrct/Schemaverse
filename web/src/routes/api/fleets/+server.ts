import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';
import { uncache } from '$lib/server/spectator';

export const GET: RequestHandler = async ({ locals }) => {
	try {
		const r = await locals.session!.client.query(
			`SELECT id, name, script, script_declarations, last_script_update_tic, enabled, shared, runtime::text AS runtime,
			        (SELECT count(*) FROM my_ships s WHERE s.fleet_id = f.id) AS ships,
			        (SELECT jsonb_agg(jsonb_build_object('tic', tic, 'action', rtrim(action), 'text', descriptor_string, 'ms', descriptor_numeric) ORDER BY id DESC)
			           FROM (SELECT * FROM my_events e WHERE e.referencing_id = f.id AND e.action IN ('FLEET_SUCCESS','FLEET_FAIL') ORDER BY id DESC LIMIT 5) last) AS runs
			   FROM my_fleets f ORDER BY id`
		);
		return json({ fleets: r.rows });
	} catch (e) {
		return fail(500, e);
	}
};

export const POST: RequestHandler = async ({ locals, request }) => {
	const { name } = await request.json();
	try {
		await locals.session!.client.query('INSERT INTO my_fleets(name) VALUES ($1)', [String(name ?? 'fleet').slice(0, 50)]);
		const r = await locals.session!.client.query('SELECT id FROM my_fleets ORDER BY id DESC LIMIT 1');
		return json({ id: r.rows[0].id });
	} catch (e) {
		return fail(400, e);
	}
};

export const PUT: RequestHandler = async ({ locals, request }) => {
	const { id, name, script, script_declarations, enabled, shared } = await request.json();
	try {
		await locals.session!.client.query(
			'UPDATE my_fleets SET name = $2, script = $3, script_declarations = $4, enabled = $5, shared = $6 WHERE id = $1',
			[Number(id), String(name).slice(0, 50), String(script), String(script_declarations), Boolean(enabled), Boolean(shared)]
		);
		// the public pages cache for a short while; a share or unshare should show at once
		uncache('fleet:' + Number(id), 'fleets', 'profile:' + locals.session!.username, 'sitemap');
		return json({ ok: true });
	} catch (e) {
		return fail(400, e);
	}
};
