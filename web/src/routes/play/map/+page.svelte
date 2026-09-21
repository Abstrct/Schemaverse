<script lang="ts">
	// Two doors. The map is the whole screen. Click a ship, pick an action, click
	// a target, and the panel shows the statement that click wrote. Run it as
	// is, or edit it first in the console. The map has no powers psql lacks.
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import SpaceMap, { type Pick } from '$lib/components/SpaceMap.svelte';
	import { game, runSql } from '$lib/game.svelte';
	import type { Snap, Ship, Planet } from '$lib/types';

	let map: SpaceMap;
	let snap = $state<Snap | null>(null);
	let selected = $state<Ship | null>(null);
	let planet = $state<Planet | null>(null);
	let shipName = $state('Explorer');
	let hover = $state('');
	type Action = 'MINE' | 'ATTACK' | 'REPAIR' | 'MOVE';
	let action = $state<Action | null>(null);
	let speed = $state(500);
	let pending = $state<{ sql: string; what: string } | null>(null);
	let ask = $state(true);
	let history = $state<{ tic: number; sql: string; ok: boolean }[]>([]);
	let lastResult = $state('');
	let nextTicIn = $state<number | null>(null);
	let period = $state(60);
	let lastTicAt = 0;

	async function load() {
		const r = await fetch('/api/map');
		if (!r.ok) return;
		snap = await r.json();
		if (selected) selected = snap!.ships.find((s) => s.id === selected!.id) ?? null;
		if (planet) planet = snap!.planets.find((p) => p.id === planet!.id) ?? null;
	}

	function pick(p: Pick) {
		if (!snap) return;
		if (p.kind === 'ship') {
			if (action === 'REPAIR' && selected && p.ship.id !== selected.id) return propose(`UPDATE my_ships SET action = 'REPAIR', action_target_id = ${p.ship.id} WHERE id = ${selected.id};`, `${name(selected)}, then ${name(p.ship)}, then Repair.`);
			selected = p.ship; planet = null; action = null; pending = null;
			return;
		}
		if (p.kind === 'space' && action !== 'MOVE') return clear();
		if (!selected || !action) {
			if (p.kind === 'planet') { planet = p.planet; selected = null; pending = null; map.flyTo(p.planet.x, p.planet.y, Math.max(map.view.k, 0.006)); }
			return;
		}
		if (p.kind === 'planet' && action === 'MINE') return propose(`UPDATE my_ships SET action = 'MINE', action_target_id = ${p.planet.id} WHERE id = ${selected.id};`, `${name(selected)}, then ${p.planet.name}, then Mine.`);
		if (p.kind === 'planet' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${Math.round(p.planet.x)}, ${Math.round(p.planet.y)}));`, `${name(selected)}, then ${p.planet.name}, then Move.`);
		if (p.kind === 'contact' && action === 'ATTACK') return propose(`UPDATE my_ships SET action = 'ATTACK', action_target_id = ${p.contact.id} WHERE id = ${selected.id};`, `${name(selected)}, then ${p.contact.player.username}'s ${p.contact.name}, then Attack.`);
		if (p.kind === 'contact' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${Math.round(p.contact.x)}, ${Math.round(p.contact.y)}));`, `${name(selected)}, then ${p.contact.name}, then Move.`);
		if (p.kind === 'space' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${p.x}, ${p.y}));`, `${name(selected)}, then a point in space, then Move.`);
	}
	const name = (s: Ship) => s.name || '#' + s.id;
	function clear() { selected = null; planet = null; action = null; pending = null; }
	const lit = (v: string) => `'${v.replace(/'/g, "''")}'`;
	const mine = (p: Planet) => snap !== null && p.conqueror_id === snap.me.id;
	function launch(p: Planet) {
		propose(`INSERT INTO my_ships(name, location) VALUES (${lit(shipName || 'Explorer')}, point(${Math.round(p.x)}, ${Math.round(p.y)}));`, `${p.name}, then Launch ship.`);
	}
	function arm(a: Action) {
		action = action === a ? null : a;
		pending = null;
		if (action === 'MOVE' && selected && snap) {
			// show the ship and its nearest planets, so there is somewhere to go
			const s = selected;
			const near = [...snap.planets].sort((p, q) => Math.hypot(p.x - s.x, p.y - s.y) - Math.hypot(q.x - s.x, q.y - s.y)).slice(0, 6);
			map.fitPoints([{ x: s.x, y: s.y }, ...near]);
		}
	}
	function propose(sql: string, what: string) {
		pending = { sql, what };
		action = null;
		if (!ask) void run();
	}
	async function run() {
		if (!pending) return;
		const sql = pending.sql;
		const r = await runSql(sql);
		const ok = !r.error;
		history = [{ tic: game.tic, sql, ok }, ...history].slice(0, 6);
		lastResult = ok ? `ok · ${r.ms} ms${r.results?.[0]?.rows?.[0] !== undefined ? ' · ' + JSON.stringify(r.results[0].rows[0]) : ''}` : 'ERROR ' + r.error.message;
		pending = null;
		await load();
		void game.refresh();
	}
	function edit() {
		if (!pending) return;
		try { sessionStorage.setItem('console.prefill', pending.sql); } catch {}
		goto('/play');
	}
	function quick(sql: string, what: string) { propose(sql, what); }
	const cursor = $derived(action === 'MOVE' ? 'crosshair' : action ? 'cell' : 'grab');
	const pstack = $derived.by(() => {
		map?.view.v;
		if (!planet || !map || !mine(planet)) return null;
		const [x, y] = map.project(planet.x, planet.y);
		const r = Math.min(64, Math.max(3, (1200 + planet.mine_limit * 30) * map.view.k));
		return { x: x + r + 22, y: y - 20 };
	});
	const stack = $derived.by(() => {
		map?.view.v;
		if (!selected || !map) return null;
		const [x, y] = map.project(selected.x, selected.y);
		const len = 200 * Math.min(0.24, Math.max(0.028, (map.view.k / 0.004) * 0.12));
		return { x: x + len / 2 + 28, y: y - 92 };
	});

	onMount(() => {
		load();
		lastTicAt = Date.now();
		const off = game.onTic(() => { const now = Date.now(); if (lastTicAt) period = Math.max(5, Math.min(600, (now - lastTicAt) / 1000)); lastTicAt = now; load(); });
		const t = setInterval(() => { nextTicIn = Math.max(0, period - (Date.now() - lastTicAt) / 1000); }, 500);
		return () => { off(); clearInterval(t); };
	});
	const mmss = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
</script>

<svelte:head><title>Map · Schemaverse</title></svelte:head>
<svelte:window onkeydown={(e) => { if (e.key === 'Escape') clear(); }} />

<div class="stage">
	<SpaceMap bind:this={map} {snap} selected={selected?.id ?? null} {cursor} onpick={pick} onhover={(h) => (hover = h?.text ?? '')} />

	<div class="modes">
		<button class="btn paper small">Live</button>
		<a class="btn quiet small" href="/play/replay">Replay</a>
		<button class="btn quiet small" onclick={() => map.fit()}>Galaxy</button>
		<button class="btn quiet small" onclick={() => map.home()}>Home</button>
	</div>

	<div class="hud tic">
		<span class="label">Next tic</span>
		<span class="big">{nextTicIn === null ? '…' : mmss(nextTicIn)}</span>
		<div class="bar glow"><i style="width: {nextTicIn === null ? 0 : 100 - (nextTicIn / period) * 100}%"></i></div>
		<span class="mono muted">LISTEN tic · T{snap?.tic ?? game.tic}</span>
	</div>

	{#if selected && stack}
		<div class="stack" style="left: {stack.x}px; top: {stack.y}px">
			{#each ['MINE', 'ATTACK', 'REPAIR', 'MOVE'] as a (a)}
				<button class="act" class:on={action === a} onclick={() => arm(a as Action)}>{a}</button>
			{/each}
		</div>
	{/if}

	{#if planet && pstack && !pending}
		<div class="stack" style="left: {pstack.x}px; top: {pstack.y}px">
			<button class="act" onclick={() => launch(planet!)}>LAUNCH SHIP</button>
		</div>
	{/if}

	<div class="hud you">
		{#if pending}
			<div class="lockup"><span class="short">YOU</span><span class="long">Clicked</span></div>
			<p class="muted">{pending.what} This is the statement that click wrote. It runs as role <span class="mono">{snap?.me.username}</span>, exactly as it would from psql.</p>
			<pre class="code">{pending.sql}</pre>
			<div class="row">
				<button class="btn primary" onclick={run}>Run <kbd>⌘↵</kbd></button>
				<button class="btn" onclick={edit}>Edit first</button>
				<button class="btn quiet" onclick={() => (pending = null)}>Cancel</button>
			</div>
		{:else if selected}
			<div class="lockup"><span class="short">SHIP</span><span class="long">{name(selected)}</span></div>
			<div class="kv mono">
				<div><span>health</span>{selected.current_health} / {selected.max_health}</div>
				<div><span>fuel</span>{selected.current_fuel} / {selected.max_fuel}</div>
				<div><span>heading</span>{selected.direction}° at {selected.speed} of {selected.max_speed}</div>
				<div><span>range</span>{selected.range}</div>
				<div><span>skills</span>A{selected.attack} D{selected.defense} E{selected.engineering} P{selected.prospecting}</div>
				<div><span>action</span>{selected.action ?? 'idle'}{selected.action_target_id ? ' → ' + selected.action_target_id : ''}</div>
			</div>
			<p class="muted">
				{#if action === 'MINE'}Now click a planet in range.{:else if action === 'ATTACK'}Now click a contact in range.{:else if action === 'REPAIR'}Now click one of your other ships.{:else if action === 'MOVE'}Now click where to go.{:else}Pick an action beside the ship, or a quick one here.{/if}
			</p>
			<div class="row wrap">
				<label class="field" for="spd" style="margin: 0">Speed</label>
				<input id="spd" class="input" style="width: 90px; height: 36px" type="number" bind:value={speed} min="0" max={selected.max_speed} />
				<button class="btn quiet small" onclick={() => quick(`SELECT refuel_ship(${selected!.id});`, `${name(selected!)}, then Refuel.`)}>Refuel</button>
				<button class="btn quiet small" onclick={() => quick(`UPDATE my_ships SET action = 'MINE', action_target_id = (SELECT planet FROM planets_in_range WHERE ship = ${selected!.id} ORDER BY distance LIMIT 1) WHERE id = ${selected!.id};`, `${name(selected!)}, then Mine nearest.`)}>Mine nearest</button>
				<button class="btn quiet small" onclick={() => quick(`UPDATE my_ships SET action = NULL, action_target_id = NULL WHERE id = ${selected!.id};`, `${name(selected!)}, then Stop.`)}>Stop</button>
				<button class="btn quiet small" onclick={clear}>Deselect</button>
			</div>
		{:else if planet}
			<div class="lockup"><span class="short">PLANET</span><span class="long">{planet.name}</span></div>
			<div class="kv mono">
				<div><span>id</span>{planet.id}</div>
				<div><span>owner</span>{planet.conqueror ? planet.conqueror.username : 'unclaimed'}{mine(planet) ? ' (you)' : ''}</div>
				<div><span>mine limit</span>{planet.mine_limit} ships per tic</div>
				<div><span>at</span>({Math.round(planet.x)}, {Math.round(planet.y)})</div>
			</div>
			{#if mine(planet)}
				<p class="muted">Ships are built on planets you hold. A launch is an INSERT into my_ships with this planet's location; the game charges 1,000.</p>
				<div class="row wrap">
					<label class="field" for="shipname" style="margin: 0">Name</label>
					<input id="shipname" class="input" style="width: 180px; height: 36px" bind:value={shipName} />
					<button class="btn primary" onclick={() => launch(planet!)}>Launch ship · 1,000</button>
					<button class="btn quiet small" onclick={clear}>Deselect</button>
				</div>
			{:else}
				<p class="muted">{planet.conqueror ? 'Held by ' + planet.conqueror.username + '. Out-mine them in a tic and it is yours.' : 'Nobody holds it. Mine it for a few tics and it is yours.'} Ships can only be launched from planets you hold.</p>
				<div class="row"><button class="btn quiet small" onclick={clear}>Deselect</button></div>
			{/if}
		{:else}
			<div class="lockup"><span class="short">THE</span><span class="long">Map</span></div>
			<p class="muted">Drag to pan, wheel to zoom, click a ship to command it. Your planets glow steel. Other players' ships appear only inside one of your ships' range. Every button here is a query, and you see it before it runs.</p>
			{#if snap && !snap.ships.length}
				<div class="row"><button class="btn primary" onclick={() => quick("INSERT INTO my_ships(name) VALUES ('Explorer');", 'Buy a ship (1000).')}>Buy a ship · 1,000</button></div>
			{/if}
		{/if}
		<label class="chk ask"><input type="checkbox" bind:checked={ask} /> ask before every click runs</label>
		<span class="tag">T{snap?.tic ?? ''}</span>
	</div>

	<div class="hud last">
		<span class="label">Last clicks, as SQL</span>
		{#if lastResult}<span class="mono" class:danger={lastResult.startsWith('ERROR')}>{lastResult}</span>{/if}
		{#each history as h, i (i)}
			<div class="h mono" class:muted={i > 0}><span class:danger={!h.ok}>T{h.tic}</span><span>{h.sql}</span></div>
		{/each}
		{#if !history.length}<span class="mono muted">nothing yet this session</span>{/if}
		<a href="/play" class="link mono">open the console →</a>
	</div>

	<div class="hover mono">{hover}</div>
</div>

<style>
	.stage { position: absolute; inset: 0; overflow: hidden; }
	.modes { position: absolute; left: 20px; top: 20px; display: flex; gap: 6px; }
	.tic { position: absolute; right: 20px; top: 20px; width: 190px; padding: 14px 16px; display: flex; flex-direction: column; gap: 8px; align-items: flex-start; }
	.tic .big { font-size: 32px; }
	.stack { position: absolute; display: flex; flex-direction: column; gap: 6px; z-index: 3; }
	.act { min-width: 110px; padding: 0 14px; height: 40px; border: 2px solid var(--fg-2); background: var(--hud); color: var(--fg); font-weight: 900; font-size: 12px; letter-spacing: 0.16em; cursor: pointer; border-radius: 0; }
	.act:hover { border-color: var(--glow); color: var(--glow); }
	.act.on { background: var(--glow); border-color: var(--glow); color: var(--void); }
	.you { position: absolute; left: 20px; bottom: 20px; width: 470px; padding: 20px 22px 18px; display: flex; flex-direction: column; gap: 12px; }
	.you p { margin: 0; font-size: 13px; line-height: 1.55; }
	.row { display: flex; gap: 8px; align-items: center; }
	.row.wrap { flex-wrap: wrap; }
	.kv { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 2px 16px; font-size: 12px; }
	.kv div { display: flex; gap: 8px; border-bottom: 1px solid var(--border); padding: 3px 0; }
	.kv span { width: 60px; color: var(--fg-2); font-family: var(--font-head); font-weight: 700; text-transform: uppercase; font-size: 9px; letter-spacing: 0.16em; padding-top: 3px; }
	.ask { margin-top: 2px; }
	.last { position: absolute; right: 20px; bottom: 20px; width: 540px; padding: 14px 18px; display: flex; flex-direction: column; gap: 5px; font-size: 11.5px; }
	.h { display: flex; gap: 10px; white-space: nowrap; overflow: hidden; }
	.h span:first-child { flex-shrink: 0; color: var(--accent); }
	.h span:last-child { overflow: hidden; text-overflow: ellipsis; }
	.hover { position: absolute; left: 50%; transform: translateX(-50%); top: 20px; font-size: 11px; color: var(--glow); pointer-events: none; }
	@media (max-width: 1100px) { .last { display: none; } .you { width: calc(100% - 40px); } }
	@media (max-width: 720px) { .you { left: 12px; right: 12px; bottom: 12px; width: auto; padding: 14px; } .tic { display: none; } .modes { left: 12px; top: 12px; } }
</style>
