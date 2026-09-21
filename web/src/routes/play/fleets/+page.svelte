<script lang="ts">
	// Autopilot. A fleet is PL/pgSQL that runs every tic as you: the body goes
	// inside a function the game generates, declarations in its DECLARE block.
	// Blocks on the left drop known-good pieces into the script; the script is
	// always the truth.
	import { onMount } from 'svelte';
	import SqlEditor from '$lib/components/SqlEditor.svelte';
	import { game, runSql } from '$lib/game.svelte';

	type Run = { tic: number; action: string; text: string | null; ms: string | null };
	type Fleet = { id: number; name: string; script: string; script_declarations: string; enabled: boolean; runtime: string; ships: number; runs: Run[] | null; last_script_update_tic: number };
	let fleets = $state<Fleet[]>([]);
	let cur = $state<Fleet | null>(null);
	let script = $state('');
	let decl = $state('');
	let name = $state('');
	let enabled = $state(false);
	let msg = $state('');
	let editor = $state<SqlEditor>();

	async function load() {
		const r = await fetch('/api/fleets');
		if (!r.ok) return;
		fleets = (await r.json()).fleets;
		if (cur) pick(fleets.find((f) => f.id === cur!.id) ?? null, false);
		else if (fleets.length) pick(fleets[0]);
	}
	function pick(f: Fleet | null, reset = true) {
		cur = f;
		if (!f) return;
		if (reset) { script = f.script; decl = f.script_declarations; name = f.name; enabled = f.enabled; }
	}
	async function create() {
		const n = prompt('Fleet name', 'fleet ' + (fleets.length + 1));
		if (!n) return;
		const r = await fetch('/api/fleets', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ name: n }) });
		await load();
		const b = await r.json();
		pick(fleets.find((f) => f.id === b.id) ?? null);
	}
	async function save() {
		if (!cur) return;
		msg = '';
		const r = await fetch('/api/fleets', { method: 'PUT', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ id: cur.id, name, script, script_declarations: decl, enabled }) });
		const b = await r.json();
		msg = r.ok ? 'Saved. Scripts compile once per tic; failures arrive on your notice channel and in my_events as FLEET_FAIL.' : 'Error: ' + b.error.message;
		await load();
		void game.refresh();
	}
	async function buyRuntime(minutes: number) {
		if (!cur) return;
		const r = await runSql(`SELECT upgrade(${cur.id}, 'FLEET_RUNTIME', ${minutes});`);
		msg = r.error ? 'Error: ' + r.error.message : r.results[0].rows[0][0] ? `${minutes} more minute${minutes > 1 ? 's' : ''} of runtime.` : 'Not enough funds (see notices).';
		await load();
		void game.refresh();
	}
	onMount(() => { load(); return game.onTic(() => load()); });

	const blocks: { name: string; decl?: string; body: string }[] = [
		{ name: 'For each idle ship', decl: 's RECORD;', body: `FOR s IN SELECT id FROM my_ships WHERE action IS NULL LOOP\n    -- ...\nEND LOOP;` },
		{ name: 'Nearest planet', decl: 'target integer;', body: `SELECT planet INTO target FROM planets_in_range WHERE ship = s.id ORDER BY distance LIMIT 1;` },
		{ name: 'If found', body: `IF target IS NOT NULL THEN\n    -- ...\nELSE\n    -- ...\nEND IF;` },
		{ name: 'Mine it', body: `UPDATE my_ships SET action = 'MINE', action_target_id = target WHERE id = s.id;` },
		{ name: 'Attack the weakest in range', body: `UPDATE my_ships SET action = 'ATTACK', action_target_id = (SELECT id FROM ships_in_range WHERE ship_in_range_of = s.id ORDER BY health LIMIT 1) WHERE id = s.id;` },
		{ name: 'Repair the hurt', body: `UPDATE my_ships SET action = 'REPAIR', action_target_id = (SELECT id FROM my_ships WHERE current_health < max_health AND id <> s.id ORDER BY current_health LIMIT 1) WHERE id = s.id;` },
		{ name: 'Refuel when low', body: `PERFORM refuel_ship(id) FROM my_ships WHERE current_fuel < max_fuel / 3;` },
		{ name: 'Head for the nearest planet', body: `PERFORM ship_course_control(s.id, 500, NULL, (SELECT location FROM planets ORDER BY location <-> (SELECT location FROM my_ships WHERE id = s.id) LIMIT 1));` },
		{ name: 'Remember a number', body: `PERFORM set_numeric_variable('last_run', current_tic());` }
	];
	function drop(b: { decl?: string; body: string }) {
		if (b.decl && !decl.includes(b.decl.split(' ')[0])) decl = (decl.trim() ? decl.trim() + '\n' : '') + b.decl;
		script = (script.trim() ? script.trimEnd() + '\n' : '') + b.body + '\n';
		editor?.focus();
	}
	const example = `-- Mine with every idle ship that has a planet in range,
-- and send the rest toward the nearest planet.
FOR s IN SELECT id FROM my_ships WHERE action IS NULL LOOP
    SELECT planet INTO target FROM planets_in_range WHERE ship = s.id ORDER BY distance LIMIT 1;
    IF target IS NOT NULL THEN
        UPDATE my_ships SET action = 'MINE', action_target_id = target WHERE id = s.id;
    ELSE
        PERFORM ship_course_control(s.id, 500, NULL,
            (SELECT location FROM planets ORDER BY location <-> (SELECT location FROM my_ships WHERE id = s.id) LIMIT 1));
    END IF;
END LOOP;`;
	const lastRun = $derived(cur?.runs?.[0] ?? null);
</script>

<svelte:head><title>Fleets · Schemaverse</title></svelte:head>

<div class="fleets">
	<aside class="side">
		<div class="lockup"><span class="short">AUTO</span><span class="long">Pilot</span></div>
		<p class="muted">A fleet is a PL/pgSQL function that runs as you every tic, for as long as its purchased runtime allows. The first minute is free.</p>
		<div class="list">
			{#each fleets as f (f.id)}
				<button class="item" class:active={cur?.id === f.id} onclick={() => pick(f)}>
					<span class="name">{f.name || 'fleet ' + f.id}</span>
					<span class="mono muted">{f.enabled ? 'on' : 'off'} · {f.runtime} · {f.ships} ships</span>
				</button>
			{/each}
			<button class="btn quiet" onclick={create}>New fleet · INSERT INTO my_fleets</button>
		</div>
		<span class="label">Blocks</span>
		<div class="blocks">
			{#each blocks as b (b.name)}
				<button class="block" onclick={() => drop(b)} disabled={!cur}>{b.name}</button>
			{/each}
			<button class="block" onclick={() => { decl = 's RECORD;\ntarget integer;'; script = example; }} disabled={!cur}>The whole mining example</button>
		</div>
	</aside>

	<section class="edit">
		{#if cur}
			<div class="row">
				<label class="field" for="fn" style="margin: 0">Name</label><input id="fn" class="input" bind:value={name} style="width: 220px; height: 36px" />
				<label class="chk"><input type="checkbox" bind:checked={enabled} /> enabled</label>
				<span class="grow"></span>
				<span class="mono muted">runtime {cur.runtime}</span>
				<button class="btn quiet small" onclick={() => buyRuntime(1)}>+1 min</button>
				<button class="btn quiet small" onclick={() => buyRuntime(10)}>+10 min</button>
				<button class="btn primary" onclick={save}>Save fleet</button>
			</div>
			{#if msg}<p class:danger={msg.startsWith('Error')} class:steel={!msg.startsWith('Error')}>{msg}</p>{/if}
			<div class="two">
				<div class="col">
					<span class="label">DECLARE</span>
					<div class="decl"><SqlEditor bind:value={decl} minHeight="70px" /></div>
					<span class="label">BEGIN … END, runs every tic as {game.me?.username}</span>
					<div class="body"><SqlEditor bind:this={editor} bind:value={script} minHeight="360px" /></div>
				</div>
				<div class="col stats">
					<div class="panel tile"><span class="big">{cur.ships}</span><span class="label">ships assigned</span></div>
					<div class="panel tile"><span class="big" class:glow={cur.enabled}>{cur.enabled ? 'ON' : 'OFF'}</span><span class="label">enabled</span></div>
					<div class="panel tile"><span class="big">{cur.runtime}</span><span class="label">runtime left</span></div>
					<div class="panel tile"><span class="big" class:danger={lastRun?.action === 'FLEET_FAIL'} class:glow={lastRun?.action === 'FLEET_SUCCESS'}>{lastRun ? (lastRun.action === 'FLEET_FAIL' ? 'FAIL' : 'OK') : '—'}</span><span class="label">last run{lastRun ? ` · T${lastRun.tic}` : ''}</span></div>
					<div class="panel runs">
						<span class="label">Last runs</span>
						{#if cur.runs?.length}
							{#each cur.runs as r, i (i)}<div class="mono" class:danger={r.action === 'FLEET_FAIL'}>T{r.tic} {r.action}{r.ms ? ' ' + r.ms : ''}{r.text ? ' — ' + r.text : ''}</div>{/each}
						{:else}<span class="mono muted">no runs yet</span>{/if}
					</div>
					<p class="muted small">Assign ships with <span class="mono">UPDATE my_ships SET fleet_id = {cur.id} WHERE …</span>. The script is wrapped in a function, so use PERFORM for calls whose result you ignore.</p>
				</div>
			</div>
		{:else}
			<p class="muted">No fleets yet. Create one with the button; it is an INSERT into my_fleets.</p>
		{/if}
	</section>
</div>

<style>
	.fleets { display: grid; grid-template-columns: 320px 1fr; gap: 28px; padding: 24px 32px; flex: 1; min-height: 0; overflow: auto; }
	.side { display: flex; flex-direction: column; gap: 14px; }
	.side p { margin: 0; font-size: 13px; }
	.list { display: flex; flex-direction: column; gap: 6px; }
	.item { display: flex; flex-direction: column; text-align: left; border: 1px solid var(--border); background: var(--bg-2); color: var(--fg); padding: 10px 12px; cursor: pointer; border-radius: 0; gap: 2px; }
	.item .name { font-weight: 900; font-size: 15px; }
	.item.active { border-color: var(--glow); }
	.blocks { display: flex; flex-direction: column; gap: 6px; }
	.block { text-align: left; border: 1px solid var(--border); background: var(--bg-2); color: var(--fg); padding: 0 12px; min-height: 40px; font-weight: 700; font-size: 11px; letter-spacing: 0.12em; text-transform: uppercase; cursor: pointer; border-radius: 0; }
	.block:hover:not(:disabled) { border-color: var(--fg); }
	.block:disabled { opacity: 0.4; }
	.edit { display: flex; flex-direction: column; gap: 12px; min-width: 0; }
	.row { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
	.grow { flex: 1; }
	.two { display: grid; grid-template-columns: minmax(0, 1fr) 300px; gap: 20px; }
	.side, .edit { min-width: 0; }
	.col { display: flex; flex-direction: column; gap: 8px; min-width: 0; }
	.stats { gap: 12px; }
	.tile { padding: 14px 16px; display: flex; flex-direction: column; gap: 6px; }
	.tile .big { font-size: 34px; }
	.runs { padding: 12px 14px; display: flex; flex-direction: column; gap: 4px; font-size: 11.5px; }
	.small { font-size: 12px; }
	p { margin: 0; }
	@media (max-width: 1100px) { .fleets { grid-template-columns: minmax(0, 1fr); overflow-x: hidden; } .two { grid-template-columns: minmax(0, 1fr); } }
	@media (max-width: 720px) {
		.fleets { padding: 16px 12px 24px; gap: 16px; align-content: start; }
		.side p { display: none; }
		.list { flex-direction: row; overflow-x: auto; scrollbar-width: none; padding-bottom: 4px; }
		.item { flex: 0 0 auto; min-width: 150px; }
		.list .btn { flex: 0 0 auto; }
		.blocks { flex-direction: row; overflow-x: auto; scrollbar-width: none; padding-bottom: 4px; }
		.block { flex: 0 0 auto; }
		.row .input { width: 100% !important; }
		.body :global(.cm-editor) { font-size: 13px; }
		.stats { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
		.stats .runs, .stats .small { grid-column: 1 / -1; }
		.tile .big { font-size: 26px; }
	}
</style>
