// Connections to the game database.
//
// Design rule for the whole web tier: a browser session has exactly the powers
// of a psql session as that player. Every query a player runs goes down a
// connection authenticated as that player's PostgreSQL role. There is no
// privileged pool that acts on players' behalf, and no SET ROLE (a player
// could RESET ROLE out of it).
import pg from 'pg';
import { env } from '$env/dynamic/private';

const { Client } = pg;

// Keep values as text where the driver would otherwise lose precision or shape.
const setParser = pg.types.setTypeParser as unknown as (oid: number, fn: (v: string) => unknown) => void;
setParser(20, (v) => (Number.isSafeInteger(Number(v)) ? Number(v) : v)); // int8
setParser(1700, (v) => v); // numeric
setParser(600, (v) => v); // point

export function baseConfig() {
	return {
		host: env.PGHOST ?? 'db',
		port: Number(env.PGPORT ?? 5432),
		database: env.PGDATABASE ?? 'schemaverse',
		application_name: 'web'
	};
}

export async function connectAs(user: string, password: string): Promise<pg.Client> {
	const client = new Client({ ...baseConfig(), user, password });
	await client.connect();
	return client;
}

/** The registrar role may only call register_player(). Its password is set by docker/migrate.sh. */
export async function registrar(): Promise<pg.Client> {
	if (!env.REGISTRAR_PASSWORD) throw new Error('REGISTRAR_PASSWORD is not set; registration is disabled');
	return connectAs('registrar', env.REGISTRAR_PASSWORD);
}

export const USERNAME_RE = /^[a-z][a-z0-9_]{1,30}$/;
