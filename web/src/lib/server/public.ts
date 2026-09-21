// What the public pages show, read as the spectator. Every query here is one
// a player could run from psql against a public view; the only thing the web
// tier adds is a sentence for each event.
import { error } from '@sveltejs/kit';
import { q, cached } from './spectator';

export type Badge = { id: number; username: string; symbol: string | null; rgb: string | null };
export type PubEvent = {
	id: number; round: number; tic: number; action: string;
	p1: number | null; p2: number | null; s1: number | null; s2: number | null; ref: number | null;
	n: string | null; x: number | null; y: number | null; toc: string; text: string;
};
export type Trophy = { trophy_id: number; name: string; description: string; weight: number; times_awarded: number; last_round_won: number };
export type RoundStats = {
	round_id: number; damage_taken: number; damage_done: number; planets_conquered: number; planets_lost: number;
	ships_built: number; ships_lost: number; fuel_mined: number; trophy_score: number;
};
export type Clock = { tic: number; round: number };

const num = (v: unknown) => (v === null || v === undefined ? 0 : Number(v));
const USERNAME = /^[a-z][a-z0-9_]{1,30}$/;

export async function clock(): Promise<Clock> {
	const [r] = await q<{ tic: string; round: number }>('SELECT (SELECT last_value FROM tic_seq) AS tic, current_round() AS round');
	return { tic: num(r.tic), round: r.round };
}

// ---- events ---------------------------------------------------------------

type Row = { id: number; round_id: number; tic: number; action: string; player_id_1: number | null; player_id_2: number | null; ship_id_1: number | null; ship_id_2: number | null; referencing_id: number | null; descriptor_numeric: string | null; x: number | null; y: number | null; toc: string };
const EVENT_COLS = `id, round_id, tic, rtrim(action) AS action, player_id_1, player_id_2, ship_id_1, ship_id_2, referencing_id, descriptor_numeric, location[0] AS x, location[1] AS y, to_json(toc)#>>'{}' AS toc`;

async function badges(ids: number[]): Promise<Map<number, Badge>> {
	const uniq = [...new Set(ids)];
	if (!uniq.length) return new Map();
	const rows = await q<Badge>('SELECT id, username, symbol, rgb FROM player_profile WHERE id = ANY($1)', [uniq]);
	return new Map(rows.map((b) => [b.id, b]));
}

/** Turn event rows into sentences. Planet names only resolve for the current round: ids restart each round. */
async function narrate(rows: Row[], current: number): Promise<PubEvent[]> {
	const who = await badges(rows.flatMap((r) => [r.player_id_1, r.player_id_2]).filter((x): x is number => x !== null));
	const planetIds = rows.filter((r) => r.action === 'CONQUER' && r.round_id === current && r.referencing_id).map((r) => r.referencing_id!);
	const planets = new Map<number, string>();
	if (planetIds.length) for (const p of await q<{ id: number; name: string }>('SELECT id, name FROM planets WHERE id = ANY($1)', [[...new Set(planetIds)]])) planets.set(p.id, p.name);
	const name = (id: number | null) => (id === null ? 'someone' : id === 0 ? 'the house' : (who.get(id)?.username ?? `player #${id}`));
	const ship = (id: number | null) => (id === null ? 'a ship' : `ship #${id}`);
	return rows.map((r) => {
		let text: string;
		switch (r.action) {
			case 'ATTACK': text = `${name(r.player_id_1)}'s ${ship(r.ship_id_1)} hit ${name(r.player_id_2)}'s ${ship(r.ship_id_2)} for ${num(r.descriptor_numeric).toLocaleString()} damage`; break;
			case 'CONQUER': text = `${name(r.player_id_1)} conquered ${planets.get(r.referencing_id ?? -1) ?? `planet #${r.referencing_id}`}${r.player_id_2 !== null ? ` from ${name(r.player_id_2)}` : ''}`; break;
			case 'EXPLODE': text = `${name(r.player_id_1)}'s ${ship(r.ship_id_1)} was destroyed`; break;
			case 'REPAIR': text = `${name(r.player_id_1)}'s ${ship(r.ship_id_1)} repaired ${ship(r.ship_id_2)} by ${num(r.descriptor_numeric).toLocaleString()}`; break;
			case 'TIC': text = `tic ${r.tic} began`; break;
			default: text = `${name(r.player_id_1)}: ${r.action.toLowerCase().replace(/_/g, ' ')}`;
		}
		return { id: r.id, round: r.round_id, tic: r.tic, action: r.action, p1: r.player_id_1, p2: r.player_id_2, s1: r.ship_id_1, s2: r.ship_id_2, ref: r.referencing_id, n: r.descriptor_numeric, x: r.x, y: r.y, toc: r.toc, text };
	});
}

// ---- players --------------------------------------------------------------

export type PlayerRow = Badge & { created: string; planets: number; trophies: number; trophy_score: number; damage_done: number; planets_conquered: number; ships_built: number; fuel_mined: number; online: boolean };

export function listPlayers(): Promise<{ players: PlayerRow[]; clock: Clock }> {
	return cached('players', 30_000, async () => {
		const rows = await q<PlayerRow>(`
			SELECT p.id, p.username, p.symbol, p.rgb, to_json(p.created)#>>'{}' AS created,
			       (SELECT count(*) FROM planets WHERE conqueror_id = p.id)::int AS planets,
			       (SELECT count(*) FROM player_trophy pt WHERE pt.player_id = p.id)::int AS trophies,
			       COALESCE((SELECT sum(t.weight) FROM player_trophy pt JOIN trophy t ON t.id = pt.trophy_id WHERE pt.player_id = p.id), 0)::int AS trophy_score,
			       COALESCE(s.damage_done, 0)::float8 AS damage_done, COALESCE(s.planets_conquered, 0)::int AS planets_conquered,
			       COALESCE(s.ships_built, 0)::int AS ships_built, COALESCE(s.fuel_mined, 0)::float8 AS fuel_mined,
			       EXISTS (SELECT 1 FROM online_players o WHERE o.id = p.id) AS online
			  FROM player_profile p
			  LEFT JOIN player_stats s ON s.player_id = p.id
			 WHERE p.id <> 0
			 ORDER BY planets DESC, trophy_score DESC, damage_done DESC, p.username
			 LIMIT 500`);
		return { players: rows, clock: await clock() };
	});
}

export type Profile = {
	player: Badge & { created: string; online: boolean };
	clock: Clock;
	planets: { id: number; name: string; mine_limit: number; x: number; y: number }[];
	stats: RoundStats | null;
	overall: RoundStats | null;
	rounds: RoundStats[];
	trophies: Trophy[];
	trophy_score: number;
	fleets: { id: number; name: string; shared_at: string; enabled: boolean }[];
	recent: PubEvent[];
};

export function getProfile(username: string): Promise<Profile> {
	if (!USERNAME.test(username)) throw error(404, 'No such player');
	return cached('profile:' + username, 30_000, async () => {
		const [player] = await q<Badge & { created: string; online: boolean }>(
			`SELECT id, username, symbol, rgb, to_json(created)#>>'{}' AS created, EXISTS (SELECT 1 FROM online_players o WHERE o.id = p.id) AS online FROM player_profile p WHERE username = $1`, [username]);
		if (!player) throw error(404, 'No such player');
		const id = player.id;
		const [clk, planets, stats, overall, rounds, trophies, fleets, events] = await Promise.all([
			clock(),
			q<Profile['planets'][number]>('SELECT id, name, mine_limit, location[0] AS x, location[1] AS y FROM planets WHERE conqueror_id = $1 ORDER BY id', [id]),
			q<RoundStats>('SELECT current_round() AS round_id, damage_taken::float8, damage_done::float8, planets_conquered::int, planets_lost::int, ships_built::int, ships_lost::int, fuel_mined::float8, 0 AS trophy_score FROM player_stats WHERE player_id = $1', [id]),
			q<RoundStats>('SELECT 0 AS round_id, damage_taken::float8, damage_done::float8, planets_conquered::int, planets_lost::int, ships_built::int, ships_lost::int, fuel_mined::float8, trophy_score::int FROM player_overall_stats WHERE player_id = $1', [id]),
			q<RoundStats>('SELECT round_id, damage_taken::float8, damage_done::float8, planets_conquered::int, planets_lost::int, ships_built::int, ships_lost::int, fuel_mined::float8, trophy_score::int FROM player_round_stats WHERE player_id = $1 AND round_id < current_round() ORDER BY round_id DESC LIMIT 50', [id]),
			q<Trophy>(`SELECT t.id AS trophy_id, t.name, t.description, t.weight, count(*)::int AS times_awarded, max(pt.round)::int AS last_round_won
			             FROM player_trophy pt JOIN trophy t ON t.id = pt.trophy_id WHERE pt.player_id = $1
			            GROUP BY t.id, t.name, t.description, t.weight ORDER BY t.weight DESC, t.name`, [id]),
			q<Profile['fleets'][number]>(`SELECT id, name, to_json(shared_at)#>>'{}' AS shared_at, enabled FROM shared_fleets WHERE player_id = $1 ORDER BY shared_at DESC`, [id]),
			q<Row>(`SELECT ${EVENT_COLS} FROM event WHERE public AND action <> 'TIC' AND (player_id_1 = $1 OR player_id_2 = $1) ORDER BY round_id DESC, id DESC LIMIT 20`, [id])
		]);
		return {
			player, clock: clk, planets, stats: stats[0] ?? null, overall: overall[0] ?? null, rounds, trophies, fleets,
			trophy_score: trophies.reduce((a, t) => a + t.weight * t.times_awarded, 0),
			recent: await narrate(events, clk.round)
		};
	});
}

// ---- shared fleets --------------------------------------------------------

export type FleetRow = { id: number; name: string; username: string; player_id: number; symbol: string | null; rgb: string | null; shared_at: string; enabled: boolean; last_script_update_tic: number; preview: string; lines: number };
export type SharedFleet = FleetRow & { script: string; script_declarations: string; others: { id: number; name: string }[]; clock: Clock };

const FLEET_COLS = `id, name, username, player_id, symbol, rgb, to_json(shared_at)#>>'{}' AS shared_at, enabled, last_script_update_tic, left(script, 400) AS preview, (length(script) - length(replace(script, E'\\n', '')) + 1)::int AS lines`;

export function listFleets(): Promise<{ fleets: FleetRow[]; clock: Clock }> {
	return cached('fleets', 30_000, async () => ({
		fleets: await q<FleetRow>(`SELECT ${FLEET_COLS} FROM shared_fleets ORDER BY shared_at DESC LIMIT 200`),
		clock: await clock()
	}));
}

export function getFleet(id: number): Promise<SharedFleet> {
	if (!Number.isInteger(id) || id < 1) throw error(404, 'No such shared fleet');
	return cached('fleet:' + id, 30_000, async () => {
		const [f] = await q<FleetRow & { script: string; script_declarations: string }>(`SELECT ${FLEET_COLS}, script, script_declarations FROM shared_fleets WHERE id = $1`, [id]);
		if (!f) throw error(404, 'No such shared fleet. Its owner may have unshared it.');
		const others = await q<{ id: number; name: string }>('SELECT id, name FROM shared_fleets WHERE player_id = $1 AND id <> $2 ORDER BY shared_at DESC LIMIT 10', [f.player_id, id]);
		return { ...f, others, clock: await clock() };
	});
}

// ---- rounds ---------------------------------------------------------------

export type RoundRow = { round_id: number; players: number; attacks: number; conquests: number; explosions: number; last_tic: number; current: boolean };

export function listRounds(): Promise<{ rounds: RoundRow[]; clock: Clock }> {
	return cached('rounds', 60_000, async () => {
		const clk = await clock();
		const rows = await q<RoundRow>(`
			SELECT r.round_id,
			       (SELECT count(*) FROM player_round_stats s WHERE s.round_id = r.round_id)::int AS players,
			       COALESCE(e.attacks, 0)::int AS attacks, COALESCE(e.conquests, 0)::int AS conquests, COALESCE(e.explosions, 0)::int AS explosions,
			       COALESCE(e.last_tic, 0)::int AS last_tic, r.round_id = current_round() AS current
			  FROM round_stats r
			  LEFT JOIN (SELECT round_id, count(*) FILTER (WHERE action = 'ATTACK') AS attacks, count(*) FILTER (WHERE action = 'CONQUER') AS conquests,
			                    count(*) FILTER (WHERE action = 'EXPLODE') AS explosions, max(tic) AS last_tic
			               FROM event WHERE public GROUP BY round_id) e ON e.round_id = r.round_id
			 ORDER BY r.round_id DESC LIMIT 200`);
		return { rounds: rows, clock: clk };
	});
}

export type Round = {
	round: number; current: boolean; clock: Clock;
	players: number; attacks: number; conquests: number; explosions: number; first_tic: number; last_tic: number;
	density: { tic: number; n: number }[];
	standings: (RoundStats & { username: string })[];
	trophies: { name: string; weight: number; username: string; description: string }[];
	headlines: PubEvent[];
	points: { tic: number; action: string; x: number; y: number; p1: number | null }[];
	planets: { id: number; name: string; x: number; y: number; conqueror_id: number | null }[];
	bounds: { min_x: number; max_x: number; min_y: number; max_y: number } | null;
};

export function getRound(n: number): Promise<Round> {
	if (!Number.isInteger(n) || n < 1) throw error(404, 'No such round');
	return cached('round:' + n, 60_000, async () => {
		const clk = await clock();
		if (n > clk.round) throw error(404, 'That round has not happened yet');
		const current = n === clk.round;
		const [[sum], density, standings, trophies, heads, points, planets] = await Promise.all([
			q<{ players: number; attacks: number; conquests: number; explosions: number; first_tic: number | null; last_tic: number | null }>(`
				SELECT (SELECT count(*) FROM player_round_stats WHERE round_id = $1)::int AS players,
				       count(*) FILTER (WHERE action = 'ATTACK')::int AS attacks, count(*) FILTER (WHERE action = 'CONQUER')::int AS conquests,
				       count(*) FILTER (WHERE action = 'EXPLODE')::int AS explosions, min(tic)::int AS first_tic, max(tic)::int AS last_tic
				  FROM event WHERE round_id = $1 AND public`, [n]),
			q<{ tic: number; n: number }>(`SELECT (tic / GREATEST(1, (SELECT max(tic) / 120 FROM event WHERE round_id = $1 AND public)))::int * GREATEST(1, (SELECT max(tic) / 120 FROM event WHERE round_id = $1 AND public))::int AS tic, count(*)::int AS n
				  FROM event WHERE round_id = $1 AND public AND action <> 'TIC' GROUP BY 1 ORDER BY 1`, [n]),
			current
				? q<RoundStats & { username: string }>(`SELECT p.username, s.player_id, current_round() AS round_id, s.damage_taken::float8, s.damage_done::float8, s.planets_conquered::int, s.planets_lost::int, s.ships_built::int, s.ships_lost::int, s.fuel_mined::float8, 0 AS trophy_score
					  FROM player_stats s JOIN player_profile p ON p.id = s.player_id ORDER BY s.planets_conquered DESC, s.damage_done DESC, s.fuel_mined DESC LIMIT 12`)
				: q<RoundStats & { username: string }>(`SELECT p.username, s.round_id, s.damage_taken::float8, s.damage_done::float8, s.planets_conquered::int, s.planets_lost::int, s.ships_built::int, s.ships_lost::int, s.fuel_mined::float8, s.trophy_score::int
					  FROM player_round_stats s JOIN player_profile p ON p.id = s.player_id WHERE s.round_id = $1 ORDER BY s.trophy_score DESC, s.planets_conquered DESC, s.damage_done DESC LIMIT 12`, [n]),
			q<Round['trophies'][number]>(`SELECT t.name, t.weight, t.description, p.username FROM player_trophy pt JOIN trophy t ON t.id = pt.trophy_id JOIN player_profile p ON p.id = pt.player_id
				  WHERE pt.round = $1 ORDER BY t.weight DESC, p.username LIMIT 200`, [n]),
			q<Row>(`SELECT ${EVENT_COLS} FROM event WHERE round_id = $1 AND public AND action IN ('CONQUER', 'EXPLODE') ORDER BY tic, id LIMIT 300`, [n]),
			q<Round['points'][number]>(`SELECT tic, rtrim(action) AS action, location[0] AS x, location[1] AS y, player_id_1 AS p1
				  FROM event WHERE round_id = $1 AND public AND action IN ('ATTACK', 'CONQUER', 'EXPLODE') AND location IS NOT NULL ORDER BY random() LIMIT 3000`, [n]),
			current ? q<Round['planets'][number]>('SELECT id, name, location[0] AS x, location[1] AS y, conqueror_id FROM planets ORDER BY id') : Promise.resolve([])
		]);
		points.sort((a, b) => a.tic - b.tic);
		const xs = [...points.map((p) => p.x), ...planets.map((p) => p.x)], ys = [...points.map((p) => p.y), ...planets.map((p) => p.y)];
		const bounds = xs.length ? { min_x: Math.min(...xs), max_x: Math.max(...xs), min_y: Math.min(...ys), max_y: Math.max(...ys) } : null;
		return {
			round: n, current, clock: clk,
			players: sum.players, attacks: sum.attacks, conquests: sum.conquests, explosions: sum.explosions,
			first_tic: sum.first_tic ?? 0, last_tic: sum.last_tic ?? 0,
			density, standings, trophies, headlines: await narrate(heads, clk.round), points, planets, bounds
		};
	});
}

/** Everything the sitemap should list. */
export function sitemapEntries(): Promise<{ players: string[]; fleets: number[]; rounds: number[] }> {
	return cached('sitemap', 300_000, async () => ({
		players: (await q<{ username: string }>('SELECT username FROM player_profile WHERE id <> 0 ORDER BY id LIMIT 5000')).map((r) => r.username),
		fleets: (await q<{ id: number }>('SELECT id FROM shared_fleets ORDER BY id LIMIT 5000')).map((r) => r.id),
		rounds: (await q<{ round_id: number }>('SELECT round_id FROM round_stats ORDER BY round_id')).map((r) => r.round_id)
	}));
}
