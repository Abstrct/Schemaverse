<script lang="ts">
	import type { PageData } from './$types';
	import { goto } from '$app/navigation';
	import { ago } from '$lib/format';
	let { data }: { data: PageData } = $props();
	const f = $derived(data.fleet);
	let msg = $state('');
	let busy = $state(false);
	const forkSql = $derived(`INSERT INTO my_fleets(name) VALUES ('${(f.name || 'fleet').replace(/'/g, "''")} (fork)');\nUPDATE my_fleets SET script = s.script, script_declarations = s.script_declarations\n  FROM shared_fleets s WHERE s.id = ${f.id} AND my_fleets.id = (SELECT max(id) FROM my_fleets);`);
	async function fork() {
		busy = true; msg = '';
		const r = await fetch('/api/fleets/fork', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ id: f.id }) });
		const b = await r.json();
		busy = false;
		if (!r.ok) { msg = 'Error: ' + (b.error?.message ?? 'could not fork'); return; }
		goto('/play/fleets');
	}
</script>

<div class="top">
	<div class="card">{@html data.card}</div>
	<aside class="side">
		<div class="lockup"><span class="short">FLEET</span><span class="long">{f.name || 'fleet ' + f.id}</span></div>
		<p class="muted">By <a href="/player/{f.username}" class="strong">{f.username}</a>. {f.lines} lines, {f.enabled ? 'running now' : 'not running'}, shared {ago(f.shared_at)}. It is wrapped in a function the game generates and runs every tic as its owner.</p>
		{#if data.me}
			<button class="btn primary" onclick={fork} disabled={busy}>Fork into my fleets</button>
			{#if msg}<p class="danger">{msg}</p>{/if}
			<p class="muted small">Copies the script and declarations into a new, disabled fleet of yours. Same as running the SQL below as <span class="mono">{data.me.username}</span>.</p>
		{:else}
			<a class="btn primary" href="/">Log in to fork it</a>
		{/if}
		<span class="label">Or from psql</span>
		<pre class="code">{forkSql}</pre>
	</aside>
</div>

<section>
	<div class="sec"><div class="lockup"><span class="short">THE</span><span class="long">Script</span></div><span class="mono muted">SELECT script_declarations, script FROM shared_fleets WHERE id = {f.id};</span></div>
	{#if f.script_declarations.trim()}
		<span class="label">DECLARE</span>
		<pre class="code">{f.script_declarations}</pre>
	{/if}
	<span class="label">BEGIN … END, every tic</span>
	<pre class="code body">{f.script}</pre>
</section>

{#if f.others.length}
	<section>
		<div class="sec"><div class="lockup"><span class="short">MORE</span><span class="long">By {f.username}</span></div></div>
		<ul class="plain">{#each f.others as o (o.id)}<li><a href="/fleet/{o.id}" class="strong">{o.name || 'fleet ' + o.id}</a></li>{/each}</ul>
	</section>
{/if}

<style>
	.top { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(280px, 1fr); gap: 32px; align-items: start; margin-bottom: 40px; }
	.card :global(svg) { width: 100%; height: auto; display: block; }
	.side { display: flex; flex-direction: column; gap: 14px; }
	.side p { margin: 0; font-size: 13px; }
	.small { font-size: 12px; }
	.strong { color: var(--fg); font-weight: 700; }
	.strong:hover { color: var(--glow); }
	section { margin-bottom: 40px; display: flex; flex-direction: column; gap: 12px; }
	.sec { display: flex; align-items: flex-end; gap: 18px; flex-wrap: wrap; }
	.sec .lockup .long { font-size: 34px; }
	.sec .mono { font-size: 11px; }
	.body { min-height: 120px; }
	.plain { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
	p { margin: 0; }
	@media (max-width: 900px) { .top { grid-template-columns: 1fr; } }
</style>
