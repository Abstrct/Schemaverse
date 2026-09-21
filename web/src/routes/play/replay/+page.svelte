<script lang="ts">
	// Round Cinema. Scrub through the round: your ships' recorded positions
	// (my_ships_flight_recorder) drawn on the map at the chosen tic, and the
	// event that happened then, narrated by read_event() with the action that
	// caused it. Everything is what psql would show you; nothing more.
	import { onMount } from 'svelte';
	import SpaceMap from '$lib/components/SpaceMap.svelte';
	import { game } from '$lib/game.svelte';
	import type { Snap, Ship, Planet } from '$lib/types';

	type Track = { ship_id: number; tic: number; x: number; y: number; name: string | null };
	type Ev = { id: number; tic: number; action: string; ship_id_1: number | null; ship_id_2: number | null; descriptor_numeric: string | null; descriptor_string: string | null; x: number | null; y: number | null; text: string };
	type Data = { tic: number; round: number; first_tic: number | null; last_tic: number | null; track: Track[]; events: Ev[]; planets: (Planet & { conqueror_id: number | null })[] };

	let map: SpaceMap;
	let data = $state<Data | null>(null);
	let tic = $state(0);
	let playing = $state(false);
	let rate = $state(4);
	let follow = $state(true);
	let snap = $state<Snap | null>(null);
	let byTic = new Map<number, Track[]>();
	let evByTic = new Map<number, Ev[]>();
	let density: number[] = $state([]);

	async function load() {
		const r = await fetch('/api/replay');
		if (!r.ok) return;
		data = await r.json();
		byTic = new Map(); evByTic = new Map();
		for (const t of data!.track) { if (!byTic.has(t.tic)) byTic.set(t.tic, []); byTic.get(t.tic)!.push(t); }
		for (const e of data!.events) { if (!evByTic.has(e.tic)) evByTic.set(e.tic, []); evByTic.get(e.tic)!.push(e); }
		const a = first, b = last;
		const bins = 160;
		density = Array.from({ length: bins }, (_, i) => {
			const lo = a + ((b - a) * i) / bins, hi = a + ((b - a) * (i + 1)) / bins;
			let n = 0; for (const [t, es] of evByTic) if (t >= lo && t < hi) n += es.length; return n;
		});
		if (!tic) tic = a;
		build();
	}
	const first = $derived(data?.first_tic ?? data?.tic ?? 0);
	const last = $derived(data?.last_tic ?? data?.tic ?? 0);
	function nearest(t: number): Track[] {
		// the latest recorded position at or before t, per ship
		const seen = new Map<number, Track>();
		for (let k = t; k >= t - 30 && k >= first; k--) {
			for (const tr of byTic.get(k) ?? []) if (!seen.has(tr.ship_id)) seen.set(tr.ship_id, tr);
			if (byTic.has(k) && seen.size) break;
		}
		return [...seen.values()];
	}
	function build() {
		if (!data) return;
		const trs = nearest(tic);
		const prev = new Map(nearest(tic - 1).map((t) => [t.ship_id, t]));
		const ships: Ship[] = trs.map((t) => {
			const p = prev.get(t.ship_id);
			const dir = p && (p.x !== t.x || p.y !== t.y) ? (Math.atan2(t.y - p.y, t.x - p.x) * 180) / Math.PI : 0;
			return { id: t.ship_id, name: t.name ?? '#' + t.ship_id, fleet_id: null, x: t.x, y: t.y, direction: dir, speed: 0, target_speed: null, target_direction: null, destination_x: null, destination_y: null, current_health: 1, max_health: 1, current_fuel: 0, max_fuel: 0, max_speed: 0, range: 0, attack: 0, defense: 0, engineering: 0, prospecting: 0, action: null, action_target_id: null, last_action_tic: null };
		});
		const xs = data.planets.map((p) => p.x), ys = data.planets.map((p) => p.y);
		snap = {
			tic, round: data.round,
			bounds: { min_x: Math.min(...xs), max_x: Math.max(...xs), min_y: Math.min(...ys), max_y: Math.max(...ys) },
			me: { id: game.me?.id ?? 0, username: game.me?.username ?? '', symbol: null, rgb: null, balance: 0, fuel_reserve: 0 },
			planets: data.planets.map((p) => ({ ...p, conqueror: null })), ships, contacts: []
		};
		if (follow && ships.length && map) {
			const cx = ships.reduce((a, s) => a + s.x, 0) / ships.length, cy = ships.reduce((a, s) => a + s.y, 0) / ships.length;
			map.flyTo(cx, cy, Math.max(map.view.k, 0.004), 300);
		}
	}
	$effect(() => { tic; build(); });
	onMount(() => {
		load();
		const t = setInterval(() => { if (playing && data) { tic = tic >= last ? first : tic + 1; } }, 1000 / 4);
		return () => clearInterval(t);
	});
	const here = $derived((evByTic.get(tic) ?? []).filter((e) => e.action !== 'TIC'));
	const headline = $derived.by(() => {
		const e = here.find((e) => /ATTACK|CONQUER|MINE_SUCCESS|BUY_SHIP|EXPLODE|FLEET_FAIL|MISSION/.test(e.action)) ?? here.find((e) => e.action !== 'TIC') ?? null;
		if (!e) return null;
		const map: Record<string, [string, string]> = { ATTACK: ['OPEN', 'FIRE'], CONQUER: ['PLANET', 'TAKEN'], MINE_SUCCESS: ['STRIKE', 'FUEL'], BUY_SHIP: ['NEW', 'SHIP'], EXPLODE: ['SHIP', 'LOST'], FLEET_FAIL: ['FLEET', 'FAILED'], FLEET_SUCCESS: ['FLEET', 'RAN'], MISSION: ['MISSION', 'DONE'], REFUEL_SHIP: ['TOP', 'UP'], UPGRADE_SHIP: ['UP', 'GRADE'] };
		return { e, words: map[e.action] ?? ['THE', e.action.replace(/_/g, ' ')] };
	});
	const sqlFor = (e: Ev) => {
		switch (e.action) {
			case 'ATTACK': return `SELECT attack(${e.ship_id_1}, ${e.ship_id_2});`;
			case 'MINE_SUCCESS': case 'MINE_FAIL': return `UPDATE my_ships SET action = 'MINE', action_target_id = … WHERE id = ${e.ship_id_1};`;
			case 'BUY_SHIP': return `INSERT INTO my_ships(name) VALUES ('${e.descriptor_string ?? '…'}');`;
			case 'REFUEL_SHIP': return `SELECT refuel_ship(${e.ship_id_1});`;
			case 'UPGRADE_SHIP': return `SELECT upgrade(${e.ship_id_1}, '${e.descriptor_string ?? '…'}', ${e.descriptor_numeric ?? '…'});`;
			case 'FLEET_SUCCESS': case 'FLEET_FAIL': return `-- fleet_script_…() ran as you`;
			default: return `SELECT read_event(${e.id});`;
		}
	};
	const pct = $derived(last > first ? ((tic - first) / (last - first)) * 100 : 0);
</script>

<svelte:head><title>Replay · Schemaverse</title></svelte:head>

<div class="stage">
	<SpaceMap bind:this={map} {snap} cursor="grab" />

	<div class="hero">
		<span class="label glow">Round {data?.round ?? ''} · tic {tic}</span>
		{#if headline}
			<div class="lockup"><span class="short">{headline.words[0]}</span><span class="long">{headline.words[1]}</span></div>
			<p>{headline.e.text}</p>
			<pre class="code">{sqlFor(headline.e)}</pre>
		{:else}
			<div class="lockup"><span class="short">ROUND</span><span class="long">Cinema</span></div>
			<p class="muted">Scrub the round. Your ships' recorded positions come from <span class="mono">my_ships_flight_recorder</span>; the narration is <span class="mono">read_event(id)</span> over <span class="mono">my_events</span>. {#if data && data.first_tic === null}Nothing recorded yet this round: fly something first.{/if}</p>
		{/if}
		{#if here.length > 1}
			<div class="more mono">{#each here.slice(0, 5) as e (e.id)}<div><span class="muted">{e.action}</span> {e.text}</div>{/each}</div>
		{/if}
	</div>

	<div class="hud timeline">
		<div class="bins">
			{#each density as d, i (i)}
				<i style="height: {Math.min(52, 3 + d * 6)}px" class:past={first + ((last - first) * i) / density.length <= tic}></i>
			{/each}
			<div class="head" style="left: {pct}%"></div>
		</div>
		<input class="scrub" type="range" min={first} max={last} bind:value={tic} aria-label="tic" />
		<div class="row">
			<button class="btn quiet small" onclick={() => (tic = Math.max(first, tic - 10))}>◀◀</button>
			<button class="btn paper" onclick={() => (playing = !playing)}>{playing ? '❚❚ Pause' : '▶ Play'}</button>
			<button class="btn quiet small" onclick={() => (tic = Math.min(last, tic + 10))}>▶▶</button>
			<span class="mono muted">tic {tic} of {first}…{last} · {data?.events.length ?? 0} events · {data?.track.length ?? 0} positions</span>
			<span class="grow"></span>
			<label class="chk"><input type="checkbox" bind:checked={follow} /> follow my fleet</label>
			<button class="btn quiet small" onclick={() => map.fit()}>Galaxy</button>
			<a class="btn quiet small" href="/play/map">Live</a>
			{#if data}<a class="btn glow small" href="/replay/{data.round}?tic={tic}" target="_blank" rel="noopener" title="The public replay of this round at this tic: everyone's attacks, conquests and losses">Share</a>{/if}
		</div>
	</div>
</div>

<style>
	.stage { position: absolute; inset: 0; overflow: hidden; }
	.hero { position: absolute; left: 32px; top: 36px; max-width: 560px; display: flex; flex-direction: column; gap: 10px; pointer-events: none; }
	.hero > * { pointer-events: auto; }
	.hero .lockup .long { font-size: 96px; }
	.hero .lockup .short { font-size: 20px; }
	.hero p { margin: 0; font-size: 15px; line-height: 1.55; }
	.hero .code { background: rgba(24,27,37,0.9); }
	.more { font-size: 11px; display: flex; flex-direction: column; gap: 2px; }
	.timeline { position: absolute; left: 24px; right: 24px; bottom: 24px; padding: 18px 22px; display: flex; flex-direction: column; gap: 10px; }
	.bins { position: relative; height: 56px; display: flex; align-items: flex-end; gap: 2px; border-bottom: 1px solid var(--border); }
	.bins i { flex: 1; background: var(--border); }
	.bins i.past { background: var(--accent); }
	.bins .head { position: absolute; top: -6px; width: 2px; height: 68px; background: var(--glow); box-shadow: 0 0 10px var(--glow); }
	.scrub { width: 100%; accent-color: var(--glow); }
	.row { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
	.grow { flex: 1; }
	@media (max-width: 720px) { .hero { left: 12px; top: 12px; right: 12px; } .hero .lockup .long { font-size: 56px; } .timeline { left: 12px; right: 12px; bottom: 12px; padding: 12px; } }
</style>
