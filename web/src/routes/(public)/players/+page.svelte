<script lang="ts">
	import type { PageData } from './$types';
	import { k } from '$lib/format';
	let { data }: { data: PageData } = $props();
</script>

<div class="head">
	<div class="lockup"><span class="short">THE</span><span class="long">Standings</span></div>
	<p class="muted">Round {data.clock.round}, tic {data.clock.tic}. Planets held now, trophies from every round. In psql: <span class="mono">SELECT * FROM player_stats;</span> and <span class="mono">SELECT * FROM trophy_case;</span></p>
</div>

<div class="panel wrap">
	<table class="grid">
		<thead><tr><th>#</th><th>Player</th><th class="num">Planets</th><th class="num">Trophies</th><th class="num">Score</th><th class="num">Damage</th><th class="num">Conquests</th><th class="num">Ships built</th><th class="num">Fuel mined</th></tr></thead>
		<tbody>
			{#each data.players as p, i (p.id)}
				<tr>
					<td class="num muted">{i + 1}</td>
					<td><a href="/player/{p.username}" class="who"><i class="sym" style="background: #{p.rgb ?? '7d96cc'}"></i>{p.username}{#if p.online}<span class="dot on" title="online"></span>{/if}</a></td>
					<td class="num">{p.planets}</td>
					<td class="num">{p.trophies}</td>
					<td class="num">{p.trophy_score}</td>
					<td class="num">{k(p.damage_done)}</td>
					<td class="num">{p.planets_conquered}</td>
					<td class="num">{p.ships_built}</td>
					<td class="num">{k(p.fuel_mined)}</td>
				</tr>
			{:else}
				<tr><td colspan="9" class="muted">No players yet. Be the first: <a href="/">register</a>.</td></tr>
			{/each}
		</tbody>
	</table>
</div>

<style>
	.head { display: flex; align-items: flex-end; gap: 28px; flex-wrap: wrap; margin-bottom: 22px; }
	.head p { margin: 0; max-width: 560px; font-size: 13px; }
	.wrap { overflow: auto; }
	.who { display: inline-flex; align-items: center; gap: 8px; color: var(--fg); font-weight: 700; }
	.who:hover { color: var(--glow); }
	.sym { width: 10px; height: 10px; display: inline-block; }
	.dot { width: 6px; height: 6px; }
</style>
