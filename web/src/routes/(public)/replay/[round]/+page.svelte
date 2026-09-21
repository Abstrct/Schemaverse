<script lang="ts">
	import type { PageData } from './$types';
	import { page } from '$app/state';
	import { replaceState } from '$app/navigation';
	import EventMap from '$lib/components/EventMap.svelte';
	import Pin from '$lib/components/Pin.svelte';
	import { trophyMotif, splitName } from '$lib/pinart';
	import { k, n } from '$lib/format';
	let { data }: { data: PageData } = $props();
	const r = $derived(data.round);
	// svelte-ignore state_referenced_locally
	let tic = $state(data.tic);
	// a client-side hop to another round brings new data; start where its link asked
	$effect(() => { tic = data.tic; });
	let playing = $state(false);
	$effect(() => {
		if (!playing) return;
		const t = setInterval(() => { tic = tic >= r.last_tic ? r.first_tic : tic + Math.max(1, Math.round(r.last_tic / 400)); }, 120);
		return () => clearInterval(t);
	});
	let copied = $state(false);
	const shareUrl = $derived(`${page.url.origin}/replay/${r.round}?tic=${tic}`);
	function share() {
		try { replaceState(`/replay/${r.round}?tic=${tic}`, {}); } catch {}
		navigator.clipboard?.writeText(shareUrl).then(() => { copied = true; setTimeout(() => (copied = false), 1500); });
	}
	const here = $derived(r.headlines.filter((e) => e.tic <= tic).slice(-8).reverse());
	const maxN = $derived(Math.max(1, ...r.density.map((d) => d.n)));
	const pct = $derived(r.last_tic > r.first_tic ? ((tic - r.first_tic) / (r.last_tic - r.first_tic)) * 100 : 0);
</script>

<div class="top">
	<div class="card">{@html data.card}</div>
	<aside class="side">
		<div class="lockup"><span class="short">ROUND</span><span class="long">{r.round}</span></div>
		<p class="muted">{r.current ? `In progress, tic ${r.clock.tic}.` : `Over after ${n(r.last_tic)} tics.`} {r.players} players. Public events only: attacks, conquests, losses. In psql: <span class="mono">SELECT * FROM event_archive WHERE round_id = {r.round} AND public;</span></p>
		<div class="tiles">
			<div class="panel tile"><span class="big">{k(r.attacks)}</span><span class="label">attacks</span></div>
			<div class="panel tile"><span class="big">{k(r.conquests)}</span><span class="label">conquests</span></div>
			<div class="panel tile"><span class="big">{k(r.explosions)}</span><span class="label">ships lost</span></div>
			<div class="panel tile"><span class="big">{r.trophies.length}</span><span class="label">trophies</span></div>
		</div>
	</aside>
</div>

<section>
	<div class="sec"><div class="lockup"><span class="short">THE</span><span class="long">Cinema</span></div><span class="mono muted">tic {tic} of {r.first_tic}…{r.last_tic}</span></div>
	<div class="stage">
		<EventMap points={r.points} planets={r.planets} bounds={r.bounds} {tic} />
		<div class="hud timeline">
			<div class="bins">
				{#each r.density as d (d.tic)}<i style="height: {Math.max(2, (d.n / maxN) * 44)}px" class:past={d.tic <= tic} title="tic {d.tic}: {d.n} events"></i>{/each}
				<div class="head" style="left: {pct}%"></div>
			</div>
			<input class="scrub" type="range" min={r.first_tic} max={r.last_tic} bind:value={tic} aria-label="tic" />
			<div class="row">
				<button class="btn quiet small" onclick={() => (tic = Math.max(r.first_tic, tic - 10))}>◀◀</button>
				<button class="btn paper small" onclick={() => (playing = !playing)}>{playing ? '❚❚ Pause' : '▶ Play'}</button>
				<button class="btn quiet small" onclick={() => (tic = Math.min(r.last_tic, tic + 10))}>▶▶</button>
				<span class="grow"></span>
				<button class="btn glow small" onclick={share}>{copied ? 'Link copied' : 'Share this moment'}</button>
			</div>
		</div>
	</div>
	{#if here.length}
		<ul class="plain feed">{#each here as e (e.id)}<li><span class="mono muted">T{e.tic}</span> {e.text}</li>{/each}</ul>
	{:else}
		<p class="muted">Nothing public has happened by tic {tic}. Scrub forward.</p>
	{/if}
</section>

<div class="cols">
	<section>
		<div class="sec"><div class="lockup"><span class="short">THE</span><span class="long">Standings</span></div><span class="mono muted">{r.current ? 'player_stats' : 'player_round_stats'}</span></div>
		<div class="panel wrap">
			<table class="grid">
				<thead><tr><th>Player</th>{#if !r.current}<th class="num">Trophy pts</th>{/if}<th class="num">Conquests</th><th class="num">Damage</th><th class="num">Ships lost</th><th class="num">Fuel mined</th></tr></thead>
				<tbody>{#each r.standings as s (s.username)}<tr><td><a href="/player/{s.username}" class="strong">{s.username}</a></td>{#if !r.current}<td class="num">{s.trophy_score}</td>{/if}<td class="num">{s.planets_conquered}</td><td class="num">{n(s.damage_done)}</td><td class="num">{s.ships_lost}</td><td class="num">{k(s.fuel_mined)}</td></tr>{:else}<tr><td colspan="6" class="muted">No standings recorded.</td></tr>{/each}</tbody>
			</table>
		</div>
	</section>
	<section>
		<div class="sec"><div class="lockup"><span class="short">TROPHIES</span><span class="long">Awarded</span></div><span class="mono muted">SELECT * FROM player_trophy WHERE round = {r.round};</span></div>
		{#if r.trophies.length}
			<div class="pins">
				{#each r.trophies as t, i (i)}
					{@const [short, long] = splitName(t.name)}
					<a href="/player/{t.username}"><Pin {short} {long} size="s" motif={trophyMotif(t.name, t.description)} won description="Awarded to {t.username}" tag="{t.weight} PTS" /></a>
				{/each}
			</div>
		{:else}
			<p class="muted">{r.current ? 'Trophies are awarded when the round ends.' : 'No trophies were awarded this round.'}</p>
		{/if}
	</section>
</div>

<style>
	.top { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(280px, 1fr); gap: 32px; align-items: start; margin-bottom: 40px; }
	.card :global(svg) { width: 100%; height: auto; display: block; }
	.side { display: flex; flex-direction: column; gap: 16px; }
	.side p { margin: 0; font-size: 13px; }
	.tiles { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
	.tile { padding: 14px 16px; display: flex; flex-direction: column; gap: 6px; }
	.tile .big { font-size: 34px; }
	section { margin-bottom: 40px; display: flex; flex-direction: column; gap: 14px; }
	.sec { display: flex; align-items: flex-end; gap: 18px; flex-wrap: wrap; }
	.sec .lockup .long { font-size: 34px; }
	.sec .mono { font-size: 11px; }
	.stage { position: relative; }
	.timeline { position: absolute; left: 16px; right: 16px; bottom: 16px; padding: 12px 16px; display: flex; flex-direction: column; gap: 8px; }
	.bins { position: relative; height: 46px; display: flex; align-items: flex-end; gap: 1px; border-bottom: 1px solid var(--border); }
	.bins i { flex: 1; background: var(--border); }
	.bins i.past { background: var(--accent); }
	.bins .head { position: absolute; top: -4px; width: 2px; height: 56px; background: var(--glow); box-shadow: 0 0 10px var(--glow); }
	.scrub { width: 100%; accent-color: var(--glow); }
	.row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
	.grow { flex: 1; }
	.cols { display: grid; grid-template-columns: 1fr 1fr; gap: 32px; }
	.pins { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
	.plain { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; font-size: 13px; }
	.strong { color: var(--fg); font-weight: 700; }
	.strong:hover { color: var(--glow); }
	.wrap { overflow: auto; }
	p { margin: 0; }
	@media (max-width: 900px) { .top, .cols { grid-template-columns: 1fr; } .timeline { position: static; margin-top: 8px; } }
</style>
