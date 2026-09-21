<script lang="ts">
	// The console: the training-wheels core. Query on the left, schema on the
	// right, results underneath, and everything the UI does for you shows the
	// SQL it ran.
	import { onMount } from 'svelte';
	import SqlEditor from '$lib/components/SqlEditor.svelte';
	import { game, runSql } from '$lib/game.svelte';

	type Field = { name: string; type: number };
	type Result = { command: string; rowCount: number; fields: Field[]; rows: unknown[][]; truncated: boolean };
	type Rel = { name: string; kind: string; columns: { name: string; type: string }[]; can_insert: boolean; can_update: boolean; can_delete: boolean; comment: string | null };
	type Fn = { name: string; args: string; returns: string; comment: string | null };

	let editor: SqlEditor;
	let sqlText = $state('SELECT username, balance, fuel_reserve FROM my_player;');
	let results = $state<Result[] | null>(null);
	let error = $state<{ message: string; hint?: string; detail?: string; position?: number } | null>(null);
	let ms = $state(0);
	let running = $state(false);
	let relations = $state<Rel[]>([]);
	let functions = $state<Fn[]>([]);
	let schemaMap = $state<Record<string, string[]>>({});
	let saved = $state<{ id: number; name: string; query_text: string }[]>([]);
	let feed = $state<{ id: number; tic: number; action: string; text: string }[]>([]);
	let side = $state<'schema' | 'saved' | 'events'>('schema');
	let history = $state<string[]>([]);
	let open = $state<string | null>(null);

	const NUM_TYPES = new Set([20, 21, 23, 700, 701, 1700]);

	async function run(text = editor?.selectedOrAll() ?? sqlText) {
		if (!text.trim()) return;
		running = true;
		error = null;
		const r = await runSql(text);
		running = false;
		if (r.error) { error = r.error; results = null; return; }
		results = r.results;
		ms = r.ms;
		history = [text, ...history.filter((h) => h !== text)].slice(0, 50);
		if (/\b(insert|update|delete|upgrade|refuel|convert_resource)\b/i.test(text)) void game.refresh();
		if (/my_query_store/i.test(text)) void loadSaved();
	}

	async function loadSchema() {
		const r = await fetch('/api/schema');
		if (!r.ok) return;
		const s = await r.json();
		relations = s.relations;
		functions = s.functions;
		const m: Record<string, string[]> = {};
		for (const rel of relations) m[rel.name] = rel.columns.map((c) => c.name);
		schemaMap = m;
	}
	async function loadSaved() {
		const r = await runSql('SELECT id, name, query_text FROM my_query_store ORDER BY name');
		if (!r.error) saved = r.results[0].rows.map((x: unknown[]) => ({ id: x[0] as number, name: x[1] as string, query_text: x[2] as string }));
	}
	async function loadFeed() {
		const r = await fetch('/api/feed?limit=40');
		if (r.ok) feed = (await r.json()).events;
	}
	async function saveQuery() {
		const name = prompt('Save as');
		if (!name) return;
		await run(`INSERT INTO my_query_store(name, query_text) VALUES (${lit(name)}, ${lit(sqlText)})\nON CONFLICT (player_id, name) DO UPDATE SET query_text = EXCLUDED.query_text, updated = now();`);
	}
	const lit = (s: string) => `'${s.replace(/'/g, "''")}'`;
	function insert(text: string) { sqlText = text; editor?.focus(); }
	function cell(v: unknown) { return v === null ? 'NULL' : typeof v === 'object' ? JSON.stringify(v) : String(v); }

	onMount(() => {
		try { const pre = sessionStorage.getItem('console.prefill'); if (pre) { sqlText = pre; sessionStorage.removeItem('console.prefill'); } } catch {}
		loadSchema(); loadSaved(); loadFeed();
		return game.onTic(() => loadFeed());
	});

	const starters = [
		['My ships', 'SELECT id, name, current_health, current_fuel, location, action, action_target_id FROM my_ships;'],
		['Buy a ship', "INSERT INTO my_ships(name) VALUES ('Explorer') RETURNING id, location;"],
		['My planets', 'SELECT id, name, mine_limit, location FROM planets WHERE conqueror_id = get_player_id(SESSION_USER);'],
		['Planets in range', 'SELECT * FROM planets_in_range;'],
		['Ships in range', 'SELECT * FROM ships_in_range;'],
		['Mine', "UPDATE my_ships SET action = 'MINE', action_target_id = (SELECT planet FROM planets_in_range WHERE ship = my_ships.id LIMIT 1) WHERE id = 1;"],
		['Set a course', 'SELECT ship_course_control(1, 500, NULL, point(100000, 100000));'],
		['Refuel', 'SELECT refuel_ship(1);'],
		['Upgrade', "SELECT upgrade(1, 'PROSPECTING', 10);"],
		['Recent events', 'SELECT id, tic, action, read_event(id) FROM my_events ORDER BY id DESC LIMIT 20;'],
		['Standings', 'SELECT username, damage_done, planets_conquered, fuel_mined, ships_built FROM player_stats ORDER BY planets_conquered DESC, fuel_mined DESC LIMIT 20;'],
		['Prices', 'SELECT * FROM price_list;']
	];
</script>

<svelte:head><title>Console · Schemaverse</title></svelte:head>

<div class="console">
	<section class="work">
		<div class="toolbar">
			<button class="btn primary" onclick={() => run()} disabled={running}>{running ? 'Running…' : 'Run'} <kbd>⌘↵</kbd></button>
			<button class="btn quiet" onclick={saveQuery}>Save</button>
			<span class="muted starters">
				{#each starters as [label, q] (label)}
					<button class="link" onclick={() => insert(q)}>{label}</button>
				{/each}
			</span>
		</div>
		<div class="editor"><SqlEditor bind:this={editor} bind:value={sqlText} schema={schemaMap} onrun={(t) => run(t)} /></div>

		<div class="results panel">
			{#if error}
				<div class="err">
					<div class="lockup"><span class="short">SQL</span><span class="long" style="font-size: 30px">Error</span></div>
					<pre>{error.message}</pre>
					{#if error.detail}<p class="muted">{error.detail}</p>{/if}
					{#if error.hint}<p class="steel">Hint: {error.hint}</p>{/if}
				</div>
			{:else if results}
				<div class="meta muted">{results.length} statement{results.length === 1 ? '' : 's'} · {ms} ms</div>
				{#each results as r, i (i)}
					<div class="result">
						<div class="cmd"><b>{r.command}</b> <span class="muted">{r.rowCount ?? 0} row{r.rowCount === 1 ? '' : 's'}{r.truncated ? ' (showing first 2000)' : ''}</span></div>
						{#if r.fields.length}
							<div class="scroll">
								<table class="grid">
									<thead><tr>{#each r.fields as f (f.name)}<th>{f.name}</th>{/each}</tr></thead>
									<tbody>
										{#each r.rows as row, ri (ri)}
											<tr>{#each row as v, ci (ci)}<td class:null={v === null} class:num={NUM_TYPES.has(r.fields[ci].type)}>{cell(v)}</td>{/each}</tr>
										{/each}
									</tbody>
								</table>
							</div>
						{/if}
					</div>
				{/each}
			{:else}
				<p class="muted hint">Results appear here. Try <button class="link" onclick={() => run('SELECT * FROM my_player;')}>SELECT * FROM my_player;</button></p>
			{/if}
			<span class="tag">T{game.tic}</span>
		</div>
	</section>

	<aside class="panel side">
		<div class="tabs">
			<button class:active={side === 'schema'} onclick={() => (side = 'schema')}>Schema</button>
			<button class:active={side === 'saved'} onclick={() => (side = 'saved')}>Saved</button>
			<button class:active={side === 'events'} onclick={() => { side = 'events'; loadFeed(); }}>Events</button>
		</div>
		<div class="scroll body">
			{#if side === 'schema'}
				{#each relations as rel (rel.name)}
					<div class="rel">
						<button class="name" onclick={() => (open = open === rel.name ? null : rel.name)}>
							<span class="kind">{rel.kind === 'materialized view' ? 'mview' : rel.kind}</span> {rel.name}
						</button>
						{#if open === rel.name}
							<div class="cols">
								{#each rel.columns as c (c.name)}<div><span class="mono">{c.name}</span> <span class="muted">{c.type}</span></div>{/each}
								<div class="acts">
									<button class="link" onclick={() => insert(`SELECT * FROM ${rel.name} LIMIT 50;`)}>select</button>
									{#if rel.can_insert}<button class="link" onclick={() => insert(`INSERT INTO ${rel.name}(${rel.columns.map((c) => c.name).join(', ')}) VALUES ();`)}>insert</button>{/if}
									{#if rel.can_update}<button class="link" onclick={() => insert(`UPDATE ${rel.name} SET  WHERE id = ;`)}>update</button>{/if}
									{#if rel.can_delete}<button class="link" onclick={() => insert(`DELETE FROM ${rel.name} WHERE id = ;`)}>delete</button>{/if}
								</div>
							</div>
						{/if}
					</div>
				{/each}
				<h4>Functions</h4>
				{#each functions as f (f.name + f.args)}
					<button class="fn" onclick={() => insert(`SELECT ${f.name}(${f.args.replace(/\w+ (\w+)/g, '$1').replace(/character varying|integer|point|bigint|text|numeric|boolean/g, '?')});`)} title={f.comment ?? ''}>
						<span class="mono">{f.name}({f.args})</span> <span class="muted">→ {f.returns}</span>
					</button>
				{/each}
			{:else if side === 'saved'}
				{#if !saved.length}<p class="muted">Nothing saved. Write a query and press Save; it goes into <span class="mono">my_query_store</span>, a table only you can see.</p>{/if}
				{#each saved as q (q.id)}
					<button class="fn" onclick={() => insert(q.query_text)}><b>{q.name}</b><br /><span class="mono muted">{q.query_text.slice(0, 80)}</span></button>
				{/each}
				<h4>History</h4>
				{#each history as h, i (i)}<button class="fn mono" onclick={() => insert(h)}>{h.slice(0, 90)}</button>{/each}
			{:else}
				{#each feed as e (e.id)}
					<div class="ev"><span class="muted">T{e.tic}</span> <span class="act">{e.action}</span><br />{e.text}</div>
				{/each}
				{#if !feed.length}<p class="muted">No events yet this round.</p>{/if}
			{/if}
		</div>
	</aside>
</div>

<style>
	.console { display: grid; grid-template-columns: 1fr 340px; gap: 16px; flex: 1; min-height: 0; padding: 16px 20px 20px; }
	.work { display: flex; flex-direction: column; gap: 10px; min-height: 0; }
	.toolbar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
	.starters { display: flex; flex-wrap: wrap; gap: 2px 12px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.12em; }
	.starters .link { color: var(--fg-2); }
	.starters .link:hover { color: var(--glow); text-decoration: none; }
	.editor { min-height: 150px; }
	.results { flex: 1; min-height: 160px; overflow: auto; padding: 14px 16px 22px; }
	.results .meta { font-size: 11px; margin-bottom: 8px; font-family: var(--font-mono); }
	.result + .result { margin-top: 16px; }
	.cmd { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.16em; margin-bottom: 6px; color: var(--fg-2); }
	.cmd b { color: var(--fg); }
	.scroll { overflow: auto; max-height: 60vh; }
	.err pre { white-space: pre-wrap; color: var(--danger); margin: 10px 0; font-family: var(--font-mono); font-size: 12.5px; }
	.err p { margin: 4px 0; font-size: 13px; }
	.hint { margin: 0; font-size: 13px; }
	.side { display: flex; flex-direction: column; min-height: 0; }
	.tabs { display: flex; border-bottom: 1px solid var(--border); }
	.tabs button { flex: 1; border: 0; background: none; padding: 12px 8px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.16em; font-size: 10px; cursor: pointer; color: var(--fg-2); }
	.tabs button.active { color: var(--fg); box-shadow: inset 0 -2px 0 var(--glow); }
	.body { flex: 1; overflow: auto; padding: 10px 12px; font-size: 12.5px; }
	.rel .name { display: block; width: 100%; text-align: left; border: 0; background: none; padding: 4px 0; cursor: pointer; font-family: var(--font-mono); font-size: 12.5px; color: var(--fg); }
	.rel .name:hover { color: var(--glow); }
	.kind { display: inline-block; width: 44px; font-weight: 700; font-size: 9px; text-transform: uppercase; letter-spacing: 0.1em; color: var(--fg-2); }
	.cols { padding: 2px 0 8px 46px; font-size: 11.5px; }
	.acts { margin-top: 4px; display: flex; gap: 10px; }
	h4 { margin: 14px 0 4px; font-size: 10px; text-transform: uppercase; letter-spacing: 0.16em; color: var(--fg-2); font-weight: 700; }
	.fn { display: block; width: 100%; text-align: left; border: 0; border-bottom: 1px solid var(--border); background: none; padding: 6px 0; cursor: pointer; font-size: 11.5px; color: var(--fg); }
	.fn:hover { color: var(--glow); }
	.ev { padding: 6px 0; border-bottom: 1px solid var(--border); font-size: 12px; }
	.ev .act { font-weight: 700; font-size: 9px; text-transform: uppercase; letter-spacing: 0.12em; color: var(--accent); }
	@media (max-width: 900px) { .console { grid-template-columns: 1fr; padding: 12px; } .side { max-height: 40vh; } }
</style>
