<script lang="ts">
	// The Academy. Every mission is a row in the mission table and a pin you
	// keep. The current one is drawn large, the Boss explains it, and the rest
	// wait in a strip. From psql: SELECT * FROM my_missions; SELECT check_missions();
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import Pin from '$lib/components/Pin.svelte';
	import type { Motif } from '$lib/pinart';
	import { game } from '$lib/game.svelte';

	type Mission = { id: number; code: string; title: string; description: string; hint: string | null; reward_balance: number; reward_fuel: number; sort: number; completed_tic: number | null };
	let missions = $state<Mission[]>([]);
	let msg = $state('');
	let focus = $state<number | null>(null);

	async function load() {
		const r = await fetch('/api/missions');
		if (r.ok) missions = (await r.json()).missions;
	}
	async function claim() {
		const r = await fetch('/api/missions', { method: 'POST' });
		const b = await r.json();
		msg = b.completed?.length ? `Claimed: ${b.completed.map((m: Mission) => m.title).join(', ')}` : 'Nothing new to claim yet.';
		await load();
		void game.refresh();
	}
	function tryIt(sql: string) {
		try { sessionStorage.setItem('console.prefill', sql); } catch {}
		goto('/play');
	}
	onMount(() => { load(); return game.onTic(() => load()); });

	const done = $derived(missions.filter((m) => m.completed_tic !== null).length);
	const current = $derived(missions.find((m) => m.id === focus) ?? missions.find((m) => m.completed_tic === null) ?? missions[0]);
	const chapters = [
		{ name: 'Reading', codes: ['buy_ship', 'name_ship', 'save_query'] },
		{ name: 'Flying', codes: ['move', 'refuel', 'explore'] },
		{ name: 'Working', codes: ['mine', 'upgrade', 'conquer'] },
		{ name: 'Fighting and automating', codes: ['first_blood', 'automate'] }
	];
	const motifs: Record<string, Motif> = { buy_ship: 'ship', name_ship: 'ship', mine: 'mine', move: 'course', refuel: 'repair', upgrade: 'fleet', save_query: 'star', explore: 'star', automate: 'fleet', first_blood: 'attack', conquer: 'planet' };
	const shorts: Record<string, [string, string]> = {
		buy_ship: ['BUY A', 'SHIP'], name_ship: ['NAME', 'IT'], mine: ['STRIKE', 'FUEL'], move: ['SET A', 'COURSE'], refuel: ['TOP', 'UP'], upgrade: ['BETTER', 'STRONGER'],
		save_query: ['KEEP A', 'QUERY'], explore: ['FAR FROM', 'HOME'], automate: ['LET IT', 'FLY ITSELF'], first_blood: ['OPEN', 'FIRE'], conquer: ['TAKE A', 'PLANET']
	};
	function split(m: Mission): [string, string] {
		if (shorts[m.code]) return shorts[m.code];
		const w = m.title.split(' ');
		return w.length === 1 ? ['THE', m.title] : [w[0], w.slice(1).join(' ')];
	}
	const stateOf = (m: Mission) => (m.completed_tic !== null ? 'done' : m.id === current?.id ? 'now' : 'todo');
	const chapterOf = (m: Mission) => chapters.find((c) => c.codes.includes(m.code))?.name ?? 'More';
	const boss: Record<string, string> = {
		buy_ship: 'Ships are rows in my_ships. An INSERT is a purchase; the game charges you and puts the ship on one of your planets.',
		name_ship: 'UPDATE changes rows in place. WHERE picks which. Forget the WHERE and you rename the whole fleet.',
		mine: 'Mining is an action, and actions resolve at the tic. Set it, then wait a minute. planets_in_range tells you what a ship can reach.',
		move: 'A course is a speed and a heading, or a speed and a destination. Never both. Ships burn fuel to change velocity.',
		refuel: 'Your reserve lives in my_player.fuel_reserve. refuel_ship moves some of it into a ship.',
		upgrade: 'Prices are a table: SELECT * FROM price_list. Skills are capped at creation, but upgrades are not.',
		save_query: 'my_query_store is a table only you can see. Row level security: \\d+ my_query_store shows the policy.',
		explore: 'Distance is the <-> operator between two points. Try it: SELECT location <-> point(0,0) FROM my_ships.',
		automate: 'A fleet is a PL/pgSQL function the ticker runs as you. The first minute of runtime is free.',
		first_blood: 'ships_in_range is other players inside one of your ships\' range. One action per ship per tic.',
		conquer: 'A planet goes to whoever mined it most in a tic, ties to the holder. Bring prospecting.'
	};
</script>

<svelte:head><title>Academy · Schemaverse</title></svelte:head>

<div class="academy">
	<aside>
		<div class="lockup"><span class="short">THE</span><span class="long">Academy</span></div>
		<p class="muted">Every mission is a row in <span class="mono">mission</span>, checked by SQL. The tic checks them for you; <span class="mono">SELECT check_missions();</span> checks now, from here or from psql.</p>
		<div class="rail">
			{#each chapters as c, i (c.name)}
				{@const ms = missions.filter((m) => c.codes.includes(m.code))}
				{@const d = ms.filter((m) => m.completed_tic !== null).length}
				<div class="ch" class:active={current && c.codes.includes(current.code)}>
					<span class="n big">{i + 1}</span>
					<div><span class="label">{c.name}</span><span class="mono muted">{d} of {ms.length}</span></div>
				</div>
			{/each}
		</div>
		<div class="progress">
			<div class="bar"><i style="width: {missions.length ? (done / missions.length) * 100 : 0}%"></i></div>
			<div class="row mono"><span>{done} of {missions.length} claimed</span><span>+{missions.filter((m) => m.completed_tic !== null).reduce((a, m) => a + m.reward_balance, 0).toLocaleString()} banked</span></div>
		</div>
		<button class="btn primary" onclick={claim}>Claim rewards</button>
		{#if msg}<p class="steel">{msg}</p>{/if}
	</aside>

	<section>
		{#if current}
			<div class="hero">
				<div class="pinbox">
					<Pin short={split(current)[0]} long={split(current)[1]} sql={current.hint ?? ''} motif={motifs[current.code] ?? 'star'} tag="R{game.me?.round ?? ''}"
						now={current.completed_tic === null} won={current.completed_tic !== null} badge={current.completed_tic !== null ? `claimed T${current.completed_tic}` : `now · +${current.reward_balance.toLocaleString()}`} />
				</div>
				<div class="coach">
					<img src="/brand/boss-mech.png" alt="The Boss, the house elephant" />
					<div class="bubble">
						<span class="label">{chapterOf(current)} · {current.title}</span>
						<p>{current.description}</p>
						<p class="muted">{boss[current.code] ?? ''}</p>
						{#if current.hint}
							<div class="row">
								<button class="btn primary" onclick={() => tryIt(current!.hint!)}>Show me the query</button>
								<button class="btn quiet" onclick={() => (focus = missions.find((m) => m.completed_tic === null && m.id !== current!.id)?.id ?? null)}>Skip for now</button>
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/if}
		<div class="strip">
			{#each missions as m (m.id)}
				<button class="pinbtn" class:current={m.id === current?.id} onclick={() => (focus = m.id)}>
					<Pin short={split(m)[0]} long={split(m)[1]} sql={m.hint ?? ''} motif={motifs[m.code] ?? 'star'} won={m.completed_tic !== null} dim={stateOf(m) === 'todo' && m.id !== current?.id} now={m.id === current?.id}
						badge={m.completed_tic !== null ? 'claimed' : m.id === current?.id ? 'now' : `+${m.reward_balance}`} tag="R{game.me?.round ?? ''}" />
				</button>
			{/each}
		</div>
	</section>
</div>

<style>
	.academy { display: grid; grid-template-columns: 320px 1fr; gap: 40px; padding: 28px 32px; flex: 1; min-height: 0; overflow: auto; }
	aside { display: flex; flex-direction: column; gap: 18px; min-width: 0; }
	aside p { margin: 0; font-size: 13px; }
	.rail { display: flex; flex-direction: column; }
	.ch { display: flex; align-items: center; gap: 14px; padding: 10px 0; border-bottom: 1px solid var(--border); opacity: 0.55; }
	.ch.active { opacity: 1; }
	.ch .n { font-size: 24px; width: 28px; }
	.ch div { display: flex; flex-direction: column; }
	.progress { display: flex; flex-direction: column; gap: 6px; }
	.row { display: flex; justify-content: space-between; gap: 10px; align-items: center; }
	section { display: flex; flex-direction: column; gap: 26px; min-width: 0; }
	.coach { min-width: 0; }
	.bubble { min-width: 0; flex: 1; }
	.hero { display: flex; gap: 32px; align-items: flex-start; }
	.pinbox { flex: 0 0 540px; max-width: 100%; }
	.pinbox :global(.pin) { border-width: 4px; }
	.coach { display: flex; gap: 18px; align-items: flex-start; flex: 1; min-width: 0; }
	.coach img { width: 150px; height: 150px; object-fit: contain; flex-shrink: 0; }
	.bubble { border: 1px solid var(--border); background: var(--bg-2); padding: 16px 18px; display: flex; flex-direction: column; gap: 8px; position: relative; }
	.bubble::before { content: ''; position: absolute; left: -7px; top: 24px; width: 12px; height: 12px; background: var(--bg-2); border-left: 1px solid var(--border); border-bottom: 1px solid var(--border); transform: rotate(45deg); }
	.bubble p { margin: 0; font-size: 13.5px; line-height: 1.55; }
	.bubble .row { justify-content: flex-start; margin-top: 6px; }
	.strip { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
	.pinbtn { border: 0; background: none; padding: 0; cursor: pointer; text-align: left; }
	.pinbtn:hover :global(.pin) { border-color: var(--steel); }
	@media (max-width: 1100px) { .academy { grid-template-columns: minmax(0, 1fr); gap: 24px; overflow-x: hidden; } .hero { flex-direction: column; } .pinbox { flex-basis: auto; width: 100%; } }
	@media (max-width: 720px) {
		.academy { padding: 16px 12px 24px; gap: 16px; }
		aside { gap: 12px; }
		aside > p { display: none; }
		.rail { flex-direction: row; overflow-x: auto; gap: 8px; scrollbar-width: none; padding-bottom: 4px; }
		.ch { flex: 0 0 auto; border: 1px solid var(--border); padding: 8px 12px; gap: 10px; }
		.ch.active { border-color: var(--glow); }
		.ch .n { font-size: 18px; width: auto; }
		.ch .mono { font-size: 10px; }
		.coach { gap: 12px; }
		.coach img { width: 90px; height: 90px; }
		.bubble { padding: 12px 14px; }
		.strip { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
	}
</style>
