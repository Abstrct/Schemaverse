// The card for each kind of public page. Built once per request from the
// same data the page shows; the page embeds the SVG, the /og route rasterises it.
import { pinSvg, type PinCard } from './pin';
import type { Profile, SharedFleet, Round } from '../public';

const pl = (n: number, w: string) => `${n.toLocaleString()} ${w}${n === 1 ? '' : 's'}`;
const k = (n: number) => (n >= 1e6 ? (n / 1e6).toFixed(1) + 'M' : n >= 1e4 ? Math.round(n / 1e3) + 'k' : Math.round(n).toLocaleString());

export function playerCard(p: Profile): PinCard {
	const s = p.stats;
	return {
		short: 'PLAYER', long: p.player.username, motif: p.trophies.length ? 'planet' : 'ship',
		sql: `SELECT * FROM trophy_case WHERE username = '${p.player.username}';`,
		description: p.trophies.length ? `${pl(p.trophies.length, 'trophy').replace('trophys', 'trophies')} in the case, ${pl(p.trophy_score, 'point')}. ${pl(p.planets.length, 'planet')} held this round.` : `No trophies yet. ${pl(p.planets.length, 'planet')} held this round.`,
		stats: [
			{ label: 'Trophies', value: String(p.trophies.length) },
			{ label: 'Planets', value: String(p.planets.length) },
			{ label: 'Damage done', value: k(s?.damage_done ?? 0) },
			{ label: 'Fuel mined', value: k(s?.fuel_mined ?? 0) }
		],
		tag: `Round ${p.clock.round}`, badge: p.player.online ? 'online now' : ''
	};
}

export function fleetCard(f: SharedFleet): PinCard {
	return {
		short: 'FLEET', long: f.name || `fleet ${f.id}`, motif: 'script',
		sql: `SELECT script FROM shared_fleets WHERE id = ${f.id};`,
		description: `A PL/pgSQL fleet script by ${f.username}, ${pl(f.lines, 'line')}. Runs every tic as its owner.`,
		code: f.script.split('\n').filter((l) => l.trim()).slice(0, 5),
		tag: `by ${f.username}`, badge: f.enabled ? 'running' : ''
	};
}

export function roundCard(r: Round): PinCard {
	return {
		short: 'ROUND', long: String(r.round), motif: 'round',
		sql: `SELECT * FROM event_archive WHERE round_id = ${r.round} AND public;`,
		description: r.current ? `In progress, tic ${r.clock.tic.toLocaleString()}. ${pl(r.players, 'player')}, ${pl(r.conquests, 'planet')} taken so far.` : `${pl(r.players, 'player')}, ${pl(r.last_tic, 'tic')}. ${pl(r.trophies.length, 'trophy').replace('trophys', 'trophies')} awarded.`,
		stats: [
			{ label: 'Players', value: String(r.players) },
			{ label: 'Attacks', value: k(r.attacks) },
			{ label: 'Conquests', value: k(r.conquests) },
			{ label: 'Ships lost', value: k(r.explosions) }
		],
		tag: r.current ? 'live' : `${r.last_tic.toLocaleString()} tics`, badge: r.current ? 'in progress' : ''
	};
}

export { pinSvg };
