<script lang="ts">
	// Two doors. The map is the whole screen. Click a ship, pick an action, click
	// a target, and the panel shows the statement that click wrote. Run it as
	// is, or edit it first in the console. The map has no powers psql lacks.
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import SpaceMap, { type Pick } from '$lib/components/SpaceMap.svelte';
	import { game, runSql } from '$lib/game.svelte';
	import { ui } from '$lib/ui.svelte';
	import { ACTION_COLORS, type Snap, type Ship, type Planet } from '$lib/types';

	let map: SpaceMap;
	let snap = $state<Snap | null>(null);
	let selected = $state<Ship | null>(null);
	let planet = $state<Planet | null>(null);
	let shipName = $state('Explorer');
	let hover = $state('');
	type Action = 'MINE' | 'ATTACK' | 'REPAIR' | 'MOVE' | 'UPGRADE';
	// Upgrades: upgrade(ship, code, quantity), priced per point in price_list.
	const UPGRADES: { code: string; label: string; field: keyof Ship; step: number }[] = [
		{ code: 'ATTACK', label: 'Attack', field: 'attack', step: 1 },
		{ code: 'DEFENSE', label: 'Defense', field: 'defense', step: 1 },
		{ code: 'ENGINEERING', label: 'Engineering', field: 'engineering', step: 1 },
		{ code: 'PROSPECTING', label: 'Prospecting', field: 'prospecting', step: 1 },
		{ code: 'MAX_HEALTH', label: 'Max health', field: 'max_health', step: 10 },
		{ code: 'MAX_FUEL', label: 'Max fuel', field: 'max_fuel', step: 100 },
		{ code: 'MAX_SPEED', label: 'Max speed', field: 'max_speed', step: 100 },
		{ code: 'RANGE', label: 'Range', field: 'range', step: 10 }
	];
	let prices = $state<Record<string, number>>({});
	let qty = $state<Record<string, number>>(Object.fromEntries(UPGRADES.map((u) => [u.code, u.step])));
	async function loadPrices() {
		const r = await runSql('SELECT code, cost FROM price_list;');
		if (!r.error) prices = Object.fromEntries(r.results[0].rows.map((x: unknown[]) => [String(x[0]).trim(), Number(x[1])]));
	}
	function buy(code: string) {
		if (!selected) return;
		const n = Math.max(1, Math.floor(Number(qty[code]) || 1));
		propose(`SELECT upgrade(${selected.id}, '${code}', ${n});`, `${name(selected)}, then Upgrade ${code.toLowerCase().replace('_', ' ')} by ${n}.`);
		action = 'UPGRADE';
	}
	let action = $state<Action | null>(null);
	let speed = $state(500);
	let pending = $state<{ sql: string; what: string } | null>(null);
	let ask = $state(true);
	let history = $state<{ tic: number; sql: string; ok: boolean }[]>([]);
	let lastResult = $state('');
	let nextTicIn = $state<number | null>(null);
	let period = $state(60);
	let lastTicAt = 0;
	// on a phone the panel is a bottom sheet: a strip when closed, most of the screen when open
	let sheet = $state(false);
	$effect(() => { if (ui.mobile && pending) sheet = true; });
	$effect(() => { if (ui.mobile && (selected || planet) && !action) sheet = true; });

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
			if (ui.mobile) reveal(p.ship.x, p.ship.y);
			return;
		}
		if (p.kind === 'space' && action !== 'MOVE') return clear();
		if (!selected || !action) {
			if (p.kind === 'planet') { planet = p.planet; selected = null; pending = null; if (ui.mobile) reveal(p.planet.x, p.planet.y, Math.max(map.view.k, 0.006)); else map.flyTo(p.planet.x, p.planet.y, Math.max(map.view.k, 0.006)); }
			return;
		}
		if (p.kind === 'planet' && action === 'MINE') return propose(`UPDATE my_ships SET action = 'MINE', action_target_id = ${p.planet.id} WHERE id = ${selected.id};`, `${name(selected)}, then ${p.planet.name}, then Mine.`);
		if (p.kind === 'planet' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${Math.round(p.planet.x)}, ${Math.round(p.planet.y)}));`, `${name(selected)}, then ${p.planet.name}, then Move.`);
		if (p.kind === 'contact' && action === 'ATTACK') return propose(`UPDATE my_ships SET action = 'ATTACK', action_target_id = ${p.contact.id} WHERE id = ${selected.id};`, `${name(selected)}, then ${p.contact.player.username}'s ${p.contact.name}, then Attack.`);
		if (p.kind === 'contact' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${Math.round(p.contact.x)}, ${Math.round(p.contact.y)}));`, `${name(selected)}, then ${p.contact.name}, then Move.`);
		if (p.kind === 'space' && action === 'MOVE') return propose(`SELECT ship_course_control(${selected.id}, ${speed}, NULL, point(${p.x}, ${p.y}));`, `${name(selected)}, then a point in space, then Move.`);
	}
	const name = (s: Ship) => s.name || '#' + s.id;
	// on a phone the sheet covers the lower part of the map, so put the thing you tapped in the upper part
	function reveal(x: number, y: number, kk = map.view.k) {
		map.flyTo(x, y - (map.view.h * 0.28) / kk, kk, 400);
	}
	function clear() { selected = null; planet = null; action = null; pending = null; }
	const lit = (v: string) => `'${v.replace(/'/g, "''")}'`;
	const mine = (p: Planet) => snap !== null && p.conqueror_id === snap.me.id;
	function launch(p: Planet) {
		propose(`INSERT INTO my_ships(name, location) VALUES (${lit(shipName || 'Explorer')}, point(${Math.round(p.x)}, ${Math.round(p.y)}));`, `${p.name}, then Launch ship.`);
	}
	function arm(a: Action) {
		action = action === a ? null : a;
		pending = null;
		// give the map back while a target is being picked
		if (ui.mobile) sheet = action === 'UPGRADE';
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
	const cursor = $derived(action === 'MOVE' ? 'crosshair' : action && action !== 'UPGRADE' ? 'cell' : 'grab');
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
		const [x, y] = map.shipScreen(selected.id) ?? map.project(selected.x, selected.y);
		const len = 200 * Math.min(0.24, Math.max(0.028, (map.view.k / 0.004) * 0.12));
		return { x: x + len / 2 + 28, y: y - 92 };
	});

	onMount(() => {
		load(); loadPrices();
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
		<button class="btn paper small desk">Live</button>
		<a class="btn quiet small desk" href="/play/replay">Replay</a>
		<button class="btn quiet small" onclick={() => map.fit()}>Galaxy</button>
		<button class="btn quiet small" onclick={() => map.home()}>Home</button>
	</div>

	<div class="hud tic">
		<span class="label">Next tic</span>
		<span class="big">{nextTicIn === null ? '…' : mmss(nextTicIn)}</span>
		<div class="bar glow"><i style="width: {nextTicIn === null ? 0 : 100 - (nextTicIn / period) * 100}%"></i></div>
		<span class="mono muted">LISTEN tic · T{snap?.tic ?? game.tic}</span>
	</div>

	{#if selected && stack && action !== 'UPGRADE' && !ui.mobile}
		<div class="stack" style="left: {stack.x}px; top: {stack.y}px">
			{#each ['MINE', 'ATTACK', 'REPAIR', 'MOVE', 'UPGRADE'] as a (a)}
				<button class="act" class:on={action === a} onclick={() => arm(a as Action)}>{a}</button>
			{/each}
		</div>
	{/if}

	{#if planet && pstack && !pending && !ui.mobile}
		<div class="stack" style="left: {pstack.x}px; top: {pstack.y}px">
			<button class="act" onclick={() => launch(planet!)}>LAUNCH SHIP</button>
		</div>
	{/if}

	<div class="hud you" class:sheet={ui.mobile} class:open={sheet}>
		{#if ui.mobile}
			<div class="sheethead">
				<button class="handle" onclick={() => (sheet = !sheet)} aria-label={sheet ? 'collapse' : 'expand'}><span></span></button>
				{#if selected && !pending}
					<div class="chips">
						{#each ['MINE', 'ATTACK', 'REPAIR', 'MOVE', 'UPGRADE'] as a (a)}
							<button class="chip" class:on={action === a} onclick={() => arm(a as Action)}>{a}</button>
						{/each}
					</div>
				{:else if planet && !pending && mine(planet)}
					<div class="chips"><button class="chip on" onclick={() => launch(planet!)}>Launch ship</button><span class="mono muted">{planet.name}</span></div>
				{:else if action && selected}
					<span class="mono glow">{action === 'MOVE' ? 'tap where to go' : action === 'MINE' ? 'tap a planet in range' : action === 'ATTACK' ? 'tap a contact' : 'tap one of your ships'}</span>
				{/if}
			</div>
		{/if}
		{#if ui.mobile && !sheet}
			<!-- collapsed: just the strip above -->
		{:else if pending}
			<div class="lockup"><span class="short">YOU</span><span class="long">Clicked</span></div>
			<p class="muted">{pending.what} This is the statement that click wrote. It runs as role <span class="mono">{snap?.me.username}</span>, exactly as it would from psql.</p>
			<pre class="code">{pending.sql}</pre>
			<div class="row">
				<button class="btn primary" onclick={run}>Run <kbd>⌘↵</kbd></button>
				<button class="btn" onclick={edit}>Edit first</button>
				<button class="btn quiet" onclick={() => (pending = null)}>Cancel</button>
			</div>
		{:else if selected && action === 'UPGRADE'}
			<div class="head"><div class="lockup"><span class="short">UPGRADE</span><span class="long">{name(selected)}</span></div><span class="grow"></span><div class="stat"><small>Balance</small><b>{Number(game.me?.balance ?? 0).toLocaleString()}</b></div></div>
			<p class="muted">Each point is one call to <span class="mono">upgrade(ship, code, quantity)</span>, priced per point in <span class="mono">price_list</span>. Skills were capped at 20 when the ship was built; upgrades are not.</p>
			<div class="ups">
				{#each UPGRADES as u (u.code)}
					{@const cost = prices[u.code] ?? 0}
					{@const n = Math.max(1, Math.floor(Number(qty[u.code]) || 1))}
					<div class="up">
						<span class="lbl">{u.label}</span>
						<span class="mono now">{selected[u.field]}</span>
						<span class="mono muted">+</span>
						<input class="input q" type="number" min="1" step={u.step} bind:value={qty[u.code]} aria-label="{u.label} quantity" />
						<span class="mono muted price">{cost} each</span>
						<button class="btn quiet small" onclick={() => buy(u.code)} disabled={!cost}>Buy · {(cost * n).toLocaleString()}</button>
					</div>
				{/each}
			</div>
			<div class="row"><button class="btn quiet small" onclick={() => (action = null)}>Back to ship</button><button class="btn quiet small" onclick={clear}>Deselect</button></div>
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
				{#if action === 'MINE'}Now click a planet in range.{:else if action === 'ATTACK'}Now click a contact in range.{:else if action === 'REPAIR'}Now click one of your other ships.{:else if action === 'MOVE'}Now click where to go.{:else}Pick an action {ui.mobile ? 'above' : 'beside the ship'}, or a quick one here.{/if}
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
			<div class="legend">
				{#each Object.entries(ACTION_COLORS) as [k, c] (k)}<span><i style="background: {c}"></i>{k.toLowerCase()}</span>{/each}
			</div>
			{#if snap && !snap.ships.length}
				<div class="row"><button class="btn primary" onclick={() => quick("INSERT INTO my_ships(name) VALUES ('Explorer');", 'Buy a ship (1000).')}>Buy a ship · 1,000</button></div>
			{/if}
		{/if}
		{#if !ui.mobile || sheet}<label class="chk ask"><input type="checkbox" bind:checked={ask} /> ask before every click runs</label>{/if}
		{#if !ui.mobile}<span class="tag">T{snap?.tic ?? ''}</span>{/if}
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
	.head { display: flex; align-items: flex-end; gap: 12px; }
	.ups { display: flex; flex-direction: column; }
	.up { display: grid; grid-template-columns: 110px 44px 12px 74px 70px 1fr; align-items: center; gap: 8px; padding: 5px 0; border-bottom: 1px solid var(--border); font-size: 12px; }
	.up .lbl { font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 0.16em; color: var(--fg-2); }
	.up .now { text-align: right; }
	.up .q { height: 32px; padding: 0 8px; font-size: 12px; }
	.up .price { font-size: 11px; }
	.up .btn { justify-self: end; }
	.legend { display: flex; gap: 14px; flex-wrap: wrap; }
	.legend span { display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 0.16em; color: var(--fg-2); }
	.legend i { width: 10px; height: 10px; display: inline-block; }
	.last { position: absolute; right: 20px; bottom: 20px; width: 540px; padding: 14px 18px; display: flex; flex-direction: column; gap: 5px; font-size: 11.5px; }
	.h { display: flex; gap: 10px; white-space: nowrap; overflow: hidden; }
	.h span:first-child { flex-shrink: 0; color: var(--accent); }
	.h span:last-child { overflow: hidden; text-overflow: ellipsis; }
	.hover { position: absolute; left: 50%; transform: translateX(-50%); top: 20px; font-size: 11px; color: var(--glow); pointer-events: none; }
	@media (max-width: 1100px) { .last { display: none; } .you { width: calc(100% - 40px); } }
	/* phone: the panel is a bottom sheet, the clock a pill, everything else out of the way */
	.you.sheet { left: 0; right: 0; bottom: 0; width: auto; padding: 0 14px calc(14px + env(safe-area-inset-bottom)); max-height: 30%; overflow: hidden; border-left: 0; border-right: 0; border-bottom: 0; gap: 10px; }
	.you.sheet.open { max-height: 78%; overflow: auto; }
	.you.sheet::before { display: none; }
	.sheethead { position: sticky; top: 0; display: flex; flex-direction: column; gap: 8px; padding-top: 6px; background: var(--hud); z-index: 1; }
	.handle { border: 0; background: none; padding: 6px 0; cursor: pointer; display: flex; justify-content: center; }
	.handle span { width: 40px; height: 4px; background: var(--fg-2); display: block; }
	.chips { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 4px; align-items: center; scrollbar-width: none; }
	.chip { flex-shrink: 0; height: 40px; padding: 0 14px; border: 2px solid var(--fg-2); background: transparent; color: var(--fg); font-weight: 900; font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; cursor: pointer; border-radius: 0; }
	.chip.on { background: var(--glow); border-color: var(--glow); color: var(--void); }
	@media (max-width: 720px) {
		.tic { width: auto; padding: 8px 10px; gap: 2px; top: 12px; right: 12px; }
		.tic .label, .tic .mono, .tic .bar { display: none; }
		.tic .big { font-size: 18px; }
		.modes { left: 12px; top: 12px; gap: 4px; }
		.modes .desk { display: none; }
		.hover { display: none; }
		.you .lockup .long { font-size: 30px; }
		.kv { grid-template-columns: 1fr; }
		.up { grid-template-columns: 90px 40px 10px 64px 1fr; }
		.up .price { display: none; }
	}
</style>
