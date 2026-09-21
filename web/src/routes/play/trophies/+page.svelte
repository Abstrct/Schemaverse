<script lang="ts">
	// Every trophy as a drawn pin. The illustration follows what the trophy is
	// about; the SQL line is how to look it up. Propose your own with an INSERT.
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import Pin from '$lib/components/Pin.svelte';
	import { trophyMotif, splitName } from '$lib/pinart';
	import { game } from '$lib/game.svelte';
	type Trophy = { id: number; name: string; description: string; weight: number; approved: boolean; mine: number; awarded: number };
	let trophies = $state<Trophy[]>([]);

	const motif = (t: Trophy) => trophyMotif(t.name, t.description);
	const split = splitName;
	const proposal = `-- A trophy is SQL that returns one player_id at round end.\nINSERT INTO trophy (name, description, weight, script)\nVALUES ('The Pacifist', 'Mined the most for the least damage dealt', 3, $$\n  SELECT player_id FROM current_stats\n   WHERE fuel_mined > 0\n   ORDER BY damage_done::numeric / fuel_mined ASC\n   LIMIT 1\n$$);`;
	function forge() {
		try { sessionStorage.setItem('console.prefill', proposal); } catch {}
		goto('/play');
	}
	onMount(async () => {
		const r = await fetch('/api/trophies');
		if (r.ok) trophies = (await r.json()).trophies;
	});
	const mine = $derived(trophies.filter((t) => t.mine > 0));
</script>

<svelte:head><title>Trophies · Schemaverse</title></svelte:head>

<div class="wrap">
	<div class="head">
		<div class="lockup"><span class="short">THE</span><span class="long">Case</span></div>
		<p class="muted">Trophies are SQL: <span class="mono">SELECT * FROM trophy;</span> shows the scripts, <span class="mono">trophy_case</span> shows who has what. Yours are outlined in steel.</p>
		<div class="grow"></div>
		<div class="stat"><small>Yours</small><b>{mine.length}</b></div>
		<div class="stat"><small>Total</small><b>{trophies.length}</b></div>
		{#if game.me}<a class="btn quiet" href="/player/{game.me.username}">Your public case ↗</a>{/if}
		<button class="btn primary" onclick={forge}>Forge a trophy</button>
	</div>
	<div class="pins">
		{#each trophies as t (t.id)}
			{@const [short, long] = split(t.name)}
			<div class="card">
				<Pin {short} {long} motif={motif(t)} won={t.mine > 0} dim={!t.approved} tag="{t.weight} PTS"
					sql="SELECT * FROM trophy_case WHERE trophy = '{t.name}' ORDER BY times_awarded DESC LIMIT 1"
					description={t.description} badge={t.mine > 0 ? `yours ×${t.mine}` : t.approved ? '' : 'proposed'} />
				<div class="foot"><span>{t.awarded} awarded</span>{#if !t.approved}<span class="muted">awaiting approval</span>{/if}</div>
			</div>
		{/each}
		{#if !trophies.length}
			<Pin short="NO" long="Trophies" description="None loaded on this server. The classics are in trophies/ in the repository." motif="star" />
		{/if}
	</div>
</div>

<style>
	.wrap { overflow: auto; padding: 28px 32px; display: flex; flex-direction: column; gap: 22px; }
	.head { display: flex; align-items: flex-end; gap: 24px; flex-wrap: wrap; }
	.head p { margin: 0; font-size: 13px; max-width: 560px; }
	.grow { flex: 1; }
	.pins { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 18px; }
	.foot { display: flex; gap: 12px; padding: 6px 2px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.16em; color: var(--fg-2); }
</style>
