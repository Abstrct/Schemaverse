<script lang="ts">
	import type { PageData } from './$types';
	import { k } from '$lib/format';
	let { data }: { data: PageData } = $props();
</script>

<div class="head">
	<div class="lockup"><span class="short">ROUND</span><span class="long">Cinema</span></div>
	<p class="muted">Every round keeps its public events. Open one to scrub through the attacks, conquests and losses, and see who took the trophies. In psql: <span class="mono">SELECT * FROM event_archive WHERE round_id = 3 AND public;</span></p>
</div>

<div class="panel wrap">
	<table class="grid">
		<thead><tr><th>Round</th><th class="num">Players</th><th class="num">Attacks</th><th class="num">Conquests</th><th class="num">Ships lost</th><th class="num">Tics</th><th></th></tr></thead>
		<tbody>
			{#each data.rounds as r (r.round_id)}
				<tr>
					<td><a href="/replay/{r.round_id}" class="strong">Round {r.round_id}</a></td>
					<td class="num">{r.players}</td><td class="num">{k(r.attacks)}</td><td class="num">{k(r.conquests)}</td><td class="num">{k(r.explosions)}</td><td class="num">{k(r.last_tic)}</td>
					<td>{#if r.current}<span class="glow label">in progress · tic {data.clock.tic}</span>{/if}</td>
				</tr>
			{:else}
				<tr><td colspan="7" class="muted">No rounds recorded yet.</td></tr>
			{/each}
		</tbody>
	</table>
</div>

<style>
	.head { display: flex; align-items: flex-end; gap: 28px; flex-wrap: wrap; margin-bottom: 22px; }
	.head p { margin: 0; max-width: 620px; font-size: 13px; }
	.wrap { overflow: auto; }
	.strong { color: var(--fg); font-weight: 700; }
	.strong:hover { color: var(--glow); }
</style>
