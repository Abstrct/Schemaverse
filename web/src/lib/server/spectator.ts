// The visitor's connection. Public pages (profiles, shared scripts, replays)
// are read through the spectator role, which the schema grants exactly what
// every player can already see about everyone else and nothing more. It is a
// pool, not a per-visitor connection, because visitors have no identity and
// share the same view of the game. Without SPECTATOR_PASSWORD the public
// pages are off and say so.
import pg from 'pg';
import { error } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import { baseConfig } from './db';

let pool: pg.Pool | null = null;

export const spectatorEnabled = () => Boolean(env.SPECTATOR_PASSWORD);

export function spectator(): pg.Pool {
	if (!env.SPECTATOR_PASSWORD) throw error(503, 'Public pages are off on this server: SPECTATOR_PASSWORD is not set.');
	pool ??= new pg.Pool({
		...baseConfig(),
		application_name: 'web-spectator',
		user: 'spectator',
		password: env.SPECTATOR_PASSWORD,
		max: 4,
		idleTimeoutMillis: 30_000,
		statement_timeout: 5_000
	});
	return pool;
}

/** Run one query as the spectator and return its rows. */
export async function q<T extends pg.QueryResultRow = pg.QueryResultRow>(sql: string, params: unknown[] = []): Promise<T[]> {
	const r = await spectator().query<T>(sql, params);
	return r.rows;
}

// A small TTL cache: a shared link that gets popular should not become a
// query storm, and a tic is a minute anyway.
const memo = new Map<string, { until: number; value: Promise<unknown> }>();
/** Forget cached public pages whose keys start with any of the prefixes, e.g. after a fleet is shared or unshared. */
export function uncache(...prefixes: string[]) {
	for (const k of memo.keys()) if (prefixes.some((p) => k.startsWith(p))) memo.delete(k);
}

export function cached<T>(key: string, ttlMs: number, fn: () => Promise<T>): Promise<T> {
	const now = Date.now();
	const hit = memo.get(key);
	if (hit && hit.until > now) return hit.value as Promise<T>;
	const value = fn();
	memo.set(key, { until: now + ttlMs, value });
	value.catch(() => memo.delete(key));
	if (memo.size > 500) for (const [k, v] of memo) if (v.until <= now) memo.delete(k);
	return value;
}
