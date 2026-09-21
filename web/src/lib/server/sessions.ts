// One live PostgreSQL connection per logged-in browser session, authenticated
// as the player. The connection also LISTENs on the tic channel and the
// player's private error channel, and fans notifications out to any open
// event streams. Passwords are never stored: if the connection drops, the
// player logs in again.
import type pg from 'pg';
import { randomBytes } from 'node:crypto';
import { connectAs } from './db';

export type Notification = { channel: string; payload: string; at: number };
export type Listener = (n: Notification) => void;

export interface Session {
	id: string;
	username: string;
	playerId: number;
	errorChannel: string;
	client: pg.Client;
	createdAt: number;
	lastUsed: number;
	listeners: Set<Listener>;
	recent: Notification[];
}

const sessions = new Map<string, Session>();
const IDLE_MS = 60 * 60 * 1000;

export async function createSession(username: string, password: string): Promise<Session> {
	const client = await connectAs(username, password);
	const me = await client.query<{ id: number; error_channel: string }>(
		'SELECT id, rtrim(error_channel) AS error_channel FROM my_player'
	);
	if (me.rowCount !== 1) {
		await client.end();
		throw new Error('that role exists but is not a player');
	}
	const session: Session = {
		id: randomBytes(24).toString('base64url'),
		username,
		playerId: me.rows[0].id,
		errorChannel: me.rows[0].error_channel,
		client,
		createdAt: Date.now(),
		lastUsed: Date.now(),
		listeners: new Set(),
		recent: []
	};
	await client.query('LISTEN tic');
	await client.query(`LISTEN "${session.errorChannel}"`);
	client.on('notification', (msg) => {
		const n: Notification = { channel: msg.channel, payload: msg.payload ?? '', at: Date.now() };
		session.recent.push(n);
		if (session.recent.length > 100) session.recent.shift();
		for (const l of session.listeners) l(n);
	});
	client.on('error', () => destroySession(session.id));
	client.on('end', () => sessions.delete(session.id));
	sessions.set(session.id, session);
	return session;
}

export function getSession(id: string | undefined): Session | undefined {
	if (!id) return undefined;
	const s = sessions.get(id);
	if (s) s.lastUsed = Date.now();
	return s;
}

export async function destroySession(id: string) {
	const s = sessions.get(id);
	if (!s) return;
	sessions.delete(id);
	try {
		await s.client.end();
	} catch {
		/* already gone */
	}
}

setInterval(() => {
	const cutoff = Date.now() - IDLE_MS;
	for (const s of sessions.values()) if (s.lastUsed < cutoff) void destroySession(s.id);
}, 60_000).unref();

export const COOKIE = 'schemaverse_session';
