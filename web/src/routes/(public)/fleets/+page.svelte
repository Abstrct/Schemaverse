<script lang="ts">
	import type { PageData } from './$types';
	import { ago } from '$lib/format';
	let { data }: { data: PageData } = $props();
</script>

<div class="head">
	<div class="lockup"><span class="short">SHARED</span><span class="long">Scripts</span></div>
	<p class="muted">Fleet scripts are PL/pgSQL that runs every tic as its owner. These are the ones players chose to publish. In psql: <span class="mono">SELECT * FROM shared_fleets;</span> Share yours with <span class="mono">UPDATE my_fleets SET shared = true WHERE id = …;</span></p>
</div>

<div class="cards">
	{#each data.fleets as f (f.id)}
		<a class="panel fleet" href="/fleet/{f.id}">
			<span class="tag">{f.lines} lines</span>
			<span class="name">{f.name || 'fleet ' + f.id}</span>
			<span class="by muted">by <b>{f.username}</b> · {f.enabled ? 'running' : 'off'} · shared {ago(f.shared_at)}</span>
			<pre class="code">{f.preview.split('\n').slice(0, 6).join('\n')}{f.preview.split('\n').length > 6 ? '\n…' : ''}</pre>
		</a>
	{:else}
		<p class="muted">Nobody has shared a script yet. The first one could be yours: write it on the Fleets tab and tick "share".</p>
	{/each}
</div>

<style>
	.head { display: flex; align-items: flex-end; gap: 28px; flex-wrap: wrap; margin-bottom: 22px; }
	.head p { margin: 0; max-width: 640px; font-size: 13px; }
	.cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 16px; }
	.fleet { display: flex; flex-direction: column; gap: 6px; padding: 16px 18px; color: var(--fg); }
	.fleet:hover { border-color: var(--glow); }
	.name { font-family: var(--font-head); font-weight: 900; font-size: 20px; letter-spacing: -0.02em; }
	.by { font-size: 12px; }
	.by b { color: var(--fg); }
	.code { margin-top: 8px; font-size: 11.5px; max-height: 150px; overflow: hidden; }
</style>
