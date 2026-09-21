<script lang="ts">
	import type { PageData } from './$types';
	import Pin from '$lib/components/Pin.svelte';
	import { trophyMotif, splitName } from '$lib/pinart';
	import { k, n, day, ago } from '$lib/format';
	let { data }: { data: PageData } = $props();
	const p = $derived(data.profile);
	const s = $derived(p.stats);
</script>

<div class="top">
	<div class="card">{@html data.card}</div>
	<aside class="side">
		<div class="lockup"><span class="short">PLAYER</span><span class="long">{p.player.username}</span></div>
		<p class="muted">{p.player.online ? 'Online now.' : 'Not connected.'} Playing since {day(p.player.created)}. Role <span class="mono">{p.player.username}</span> in PostgreSQL, like everyone here.</p>
		<div class="tiles">
			<div class="panel tile"><span class="big">{p.trophies.length}</span><span class="label">trophies</span></div>
			<div class="panel tile"><span class="big">{p.trophy_score}</span><span class="label">points</span></div>
			<div class="panel tile"><span class="big">{p.planets.length}</span><span class="label">planets held</span></div>
			<div class="panel tile"><span class="big">{k(s?.damage_done)}</span><span class="label">damage this round</span></div>
		</div>
		{#if data.me?.username === p.player.username}
			<p class="muted small">This is your public page. Share it: everyone sees exactly this.</p>
		{/if}
	</aside>
</div>

<section>
	<div class="sec"><div class="lockup"><span class="short">THE</span><span class="long">Case</span></div><span class="mono muted">SELECT * FROM trophy_case WHERE username = '{p.player.username}';</span></div>
	{#if p.trophies.length}
		<div class="pins">
			{#each p.trophies as t (t.trophy_id)}
				{@const [short, long] = splitName(t.name)}
				<Pin {short} {long} motif={trophyMotif(t.name, t.description)} won description={t.description} tag="{t.weight} PTS" badge={t.times_awarded > 1 ? `×${t.times_awarded}` : `round ${t.last_round_won}`} />
			{/each}
		</div>
	{:else}
		<p class="muted">No trophies yet. Trophies are awarded when a round ends; <a href="/replays">the replays</a> show who won what.</p>
	{/if}
</section>

<div class="cols">
	<section>
		<div class="sec"><div class="lockup"><span class="short">THIS</span><span class="long">Round</span></div><span class="mono muted">round {p.clock.round}</span></div>
		{#if s}
			<table class="grid">
				<tbody>
					<tr><td>Damage done</td><td class="num">{n(s.damage_done)}</td></tr>
					<tr><td>Damage taken</td><td class="num">{n(s.damage_taken)}</td></tr>
					<tr><td>Planets conquered</td><td class="num">{s.planets_conquered}</td></tr>
					<tr><td>Planets lost</td><td class="num">{s.planets_lost}</td></tr>
					<tr><td>Ships built</td><td class="num">{s.ships_built}</td></tr>
					<tr><td>Ships lost</td><td class="num">{s.ships_lost}</td></tr>
					<tr><td>Fuel mined</td><td class="num">{n(s.fuel_mined)}</td></tr>
				</tbody>
			</table>
		{:else}<p class="muted">No stats yet this round.</p>{/if}
		{#if p.planets.length}
			<span class="label">Planets held</span>
			<ul class="plain">{#each p.planets as pl (pl.id)}<li><span class="mono">{pl.name}</span> <span class="muted">· mine limit {pl.mine_limit} · ({Math.round(pl.x)}, {Math.round(pl.y)})</span></li>{/each}</ul>
		{/if}
	</section>

	<section>
		<div class="sec"><div class="lockup"><span class="short">SHARED</span><span class="long">Scripts</span></div><span class="mono muted">SELECT * FROM shared_fleets WHERE username = '{p.player.username}';</span></div>
		{#if p.fleets.length}
			<ul class="plain">
				{#each p.fleets as f (f.id)}<li><a href="/fleet/{f.id}" class="strong">{f.name || 'fleet ' + f.id}</a> <span class="muted">· {f.enabled ? 'running' : 'off'} · shared {ago(f.shared_at)}</span></li>{/each}
			</ul>
		{:else}<p class="muted">No fleet scripts shared. A player publishes one with <span class="mono">UPDATE my_fleets SET shared = true</span>.</p>{/if}

		<div class="sec"><div class="lockup"><span class="short">PUBLIC</span><span class="long">Record</span></div></div>
		{#if p.recent.length}
			<ul class="plain feed">
				{#each p.recent as e (e.id)}<li><a class="mono muted" href="/replay/{e.round}?tic={e.tic}">R{e.round} T{e.tic}</a> {e.text}</li>{/each}
			</ul>
		{:else}<p class="muted">Nothing public yet. Attacks, conquests and losses show here.</p>{/if}
	</section>
</div>

{#if p.rounds.length}
	<section>
		<div class="sec"><div class="lockup"><span class="short">PAST</span><span class="long">Rounds</span></div><span class="mono muted">SELECT * FROM player_round_stats;</span></div>
		<div class="panel wrap">
			<table class="grid">
				<thead><tr><th>Round</th><th class="num">Trophy pts</th><th class="num">Damage</th><th class="num">Conquests</th><th class="num">Ships built</th><th class="num">Ships lost</th><th class="num">Fuel mined</th></tr></thead>
				<tbody>{#each p.rounds as r (r.round_id)}<tr><td><a href="/replay/{r.round_id}">Round {r.round_id}</a></td><td class="num">{r.trophy_score}</td><td class="num">{n(r.damage_done)}</td><td class="num">{r.planets_conquered}</td><td class="num">{r.ships_built}</td><td class="num">{r.ships_lost}</td><td class="num">{n(r.fuel_mined)}</td></tr>{/each}</tbody>
			</table>
		</div>
	</section>
{/if}

<style>
	.top { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(280px, 1fr); gap: 32px; align-items: start; margin-bottom: 40px; }
	.card :global(svg) { width: 100%; height: auto; display: block; }
	.side { display: flex; flex-direction: column; gap: 16px; }
	.side p { margin: 0; font-size: 13px; }
	.tiles { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
	.tile { padding: 14px 16px; display: flex; flex-direction: column; gap: 6px; }
	.tile .big { font-size: 34px; }
	.small { font-size: 12px; }
	section { margin-bottom: 40px; display: flex; flex-direction: column; gap: 14px; }
	.sec { display: flex; align-items: flex-end; gap: 18px; flex-wrap: wrap; }
	.sec .lockup .long { font-size: 34px; }
	.sec .mono { font-size: 11px; }
	.pins { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 18px; }
	.cols { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; }
	.plain { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; font-size: 13px; }
	.feed li { line-height: 1.5; }
	.strong { color: var(--fg); font-weight: 700; }
	.strong:hover { color: var(--glow); }
	.wrap { overflow: auto; }
	p { margin: 0; }
	@media (max-width: 900px) { .top, .cols { grid-template-columns: 1fr; } }
</style>
