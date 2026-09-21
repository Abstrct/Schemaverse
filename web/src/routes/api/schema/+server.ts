// What the player can see of the schema: relations they may SELECT from, their
// columns, and functions they may execute. Feeds the console's completion and
// the schema browser.
import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { fail } from '$lib/server/respond';

export const GET: RequestHandler = async ({ locals }) => {
	const c = locals.session!.client;
	try {
		const rels = await c.query(`
			SELECT c.relname AS name,
			       CASE c.relkind WHEN 'r' THEN 'table' WHEN 'p' THEN 'table' WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' END AS kind,
			       obj_description(c.oid, 'pg_class') AS comment,
			       (SELECT jsonb_agg(jsonb_build_object('name', a.attname, 'type', format_type(a.atttypid, a.atttypmod)) ORDER BY a.attnum)
			          FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
			           AND has_column_privilege(c.oid, a.attnum, 'SELECT')) AS columns,
			       has_table_privilege(c.oid, 'INSERT') AS can_insert,
			       has_table_privilege(c.oid, 'UPDATE') AS can_update,
			       has_table_privilege(c.oid, 'DELETE') AS can_delete
			  FROM pg_class c
			 WHERE c.relnamespace = 'public'::regnamespace
			   AND c.relkind IN ('r', 'p', 'v', 'm')
			   AND c.relname NOT LIKE 'event_round_%' AND c.relname <> 'event_default'
			   AND has_table_privilege(c.oid, 'SELECT')
			   AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped AND has_column_privilege(c.oid, a.attnum, 'SELECT'))
			 ORDER BY c.relkind, c.relname`);
		const funcs = await c.query(`
			SELECT p.proname AS name,
			       pg_get_function_identity_arguments(p.oid) AS args,
			       pg_get_function_result(p.oid) AS returns,
			       obj_description(p.oid, 'pg_proc') AS comment
			  FROM pg_proc p
			 WHERE p.pronamespace = 'public'::regnamespace
			   AND p.prokind = 'f'
			   AND has_function_privilege(p.oid, 'EXECUTE')
			   AND p.proname NOT LIKE 'fleet\\_script\\_%' AND p.proname NOT LIKE 'trophy\\_script\\_%'
			   AND p.proname NOT LIKE '\\_%'
			   AND NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_extension e ON e.oid = d.refobjid WHERE d.objid = p.oid)
			 ORDER BY p.proname`);
		return json({ relations: rels.rows, functions: funcs.rows });
	} catch (e) {
		return fail(500, e);
	}
};
