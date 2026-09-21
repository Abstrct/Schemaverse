import { json } from '@sveltejs/kit';

/** Turn a PostgreSQL error into something the console can render. */
export function pgError(e: unknown) {
	const err = e as { message?: string; code?: string; position?: string; hint?: string; detail?: string; where?: string };
	return {
		message: err?.message ?? String(e),
		code: err?.code,
		position: err?.position ? Number(err.position) : undefined,
		hint: err?.hint,
		detail: err?.detail,
		where: err?.where
	};
}

export function fail(status: number, e: unknown) {
	return json({ error: pgError(e) }, { status });
}
