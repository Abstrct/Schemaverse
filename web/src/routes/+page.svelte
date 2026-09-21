<script lang="ts">
	// The front door: space, the wordmark, three pins, and a login that is a
	// real PostgreSQL connection as you.
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import { game } from '$lib/game.svelte';
	import Pin from '$lib/components/Pin.svelte';
	import SpaceMap from '$lib/components/SpaceMap.svelte';
	import type { Snap } from '$lib/types';

	let username = $state('');
	let password = $state('');
	let mode = $state<'login' | 'register'>('login');
	let busy = $state(false);
	let error = $state('');
	let demo = $state<Snap | null>(null);

	onMount(async () => {
		document.documentElement.dataset.theme = 'dark';
		if (await game.refresh()) goto('/play/map');
		// A small made-up galaxy for the backdrop. Nothing here is real data.
		let s = 7;
		const rnd = () => (s = (s * 9301 + 49297) % 233280) / 233280;
		const planets = Array.from({ length: 34 }, (_, i) => ({ id: i + 1, name: 'planet ' + (i + 1), x: rnd() * 2e6 - 1e6, y: rnd() * 1.2e6 - 6e5, mine_limit: 20 + Math.floor(rnd() * 60), conqueror_id: i % 6 === 0 ? 1 : i % 7 === 0 ? 2 : null, conqueror: null }));
		const ships = Array.from({ length: 9 }, (_, i) => ({ id: 100 + i, name: '', fleet_id: null, x: planets[i * 3].x + 40000 + rnd() * 60000, y: planets[i * 3].y + rnd() * 60000, direction: Math.floor(rnd() * 360), speed: 100, target_speed: null, target_direction: null, destination_x: i % 2 ? planets[(i * 5) % 34].x : null, destination_y: i % 2 ? planets[(i * 5) % 34].y : null, current_health: 100, max_health: 100, current_fuel: 100, max_fuel: 100, max_speed: 1000, range: 80000, attack: 5, defense: 5, engineering: 5, prospecting: 5, action: i % 2 ? null : 'MINE', action_target_id: i % 2 ? null : planets[i * 3].id, last_action_tic: null }));
		demo = { tic: 0, round: 0, bounds: { min_x: -1e6, max_x: 1e6, min_y: -6e5, max_y: 6e5 }, me: { id: 1, username: '', symbol: null, rgb: null, balance: 0, fuel_reserve: 0 }, planets, ships, contacts: [] };
	});

	async function submit(e: Event) {
		e.preventDefault();
		busy = true;
		error = '';
		const r = await fetch(`/api/auth/${mode}`, {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ username: username.trim().toLowerCase(), password })
		});
		const body = await r.json();
		busy = false;
		if (!r.ok) { error = body.error?.message ?? 'something went wrong'; return; }
		goto('/play/map');
	}
</script>

<svelte:head><title>Schemaverse · A space war played in SQL</title></svelte:head>

<div class="front">
	<div class="space"><SpaceMap snap={demo} cursor="default" /></div>
	<div class="veil"></div>
	<main>
		<section class="hero">
			<img class="mark" src="/brand/wordmark-light.svg" alt="Schemaverse" width="106" height="30" />
			<h1 class="big">A space war<br />played in SQL.</h1>
			<p class="tag">Every player is a PostgreSQL role. Buy ships with INSERT, steer them with a function call, read the battle in a view. Write PL/pgSQL and the database flies your fleet for you. Or click the map, and read the query it wrote.</p>
			<div class="pins">
				<Pin short="SELECT" long="Attack" sql="SELECT attack(ship_in_range_of, id) FROM ships_in_range;" motif="attack" tag="DC19" />
				<Pin short="SELECT" long="Mine" sql="UPDATE my_ships SET action = 'MINE', action_target_id = planet;" motif="mine" tag="DC19" />
				<Pin short="SELECT" long="Repair" sql="SELECT repair(id, id) FROM my_ships WHERE current_health < max_health;" motif="repair" tag="DC19" />
			</div>
			<p class="mono muted psql">psql -h {page.url.hostname} -U &lt;you&gt; schemaverse</p>
		</section>

		<form class="hud login" onsubmit={submit}>
			<div class="lockup">
				<span class="short">{mode === 'login' ? 'PLAYER' : 'NEW'}</span>
				<span class="long">{mode === 'login' ? 'Login' : 'Player'}</span>
			</div>
			<label class="field" for="u">Username</label>
			<input id="u" class="input" bind:value={username} autocomplete="username" pattern="[a-z][a-z0-9_]{'{'}1,30{'}'}" required />
			<label class="field" for="p" style="margin-top: 12px">Password</label>
			<input id="p" class="input" type="password" bind:value={password} autocomplete={mode === 'login' ? 'current-password' : 'new-password'} minlength="8" required />
			{#if error}<p class="danger">{error}</p>{/if}
			<div class="row">
				<button class="btn primary" disabled={busy}>{mode === 'login' ? 'Open a connection' : 'Create player'}</button>
				<button type="button" class="btn quiet" onclick={() => (mode = mode === 'login' ? 'register' : 'login')}>
					{mode === 'login' ? 'New here? Register' : 'Have a player? Log in'}
				</button>
			</div>
			<p class="muted small">Your username becomes a PostgreSQL role. The same login works in psql and here, and the browser can do nothing psql cannot.</p>
		</form>
	</main>
	<footer>
		<span><b>Learn SQL.</b> Every action is a query, and the interface shows you each one.</span>
		<span><b>Write an AI.</b> Fleet scripts are PL/pgSQL that runs every tic as you.</span>
		<span><b>Break it.</b> Security is PostgreSQL's security. If you get past it, <a href="https://github.com/abstrct/schemaverse/issues">tell us how</a>.</span>
		<span class="links">
			<a href="https://github.com/abstrct/schemaverse" title="Source on GitHub">
				<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>
				Source on GitHub
			</a>
			<a href="/players">Standings</a>
			<a href="/fleets">Scripts</a>
			<a href="/replays">Replays</a>
			<a href="https://github.com/abstrct/schemaverse/blob/master/docs/PLAYING.md">How to play</a>
			<a href="https://github.com/abstrct/schemaverse/blob/master/docker/README.md">Run your own</a>
		</span>
	</footer>
</div>

<style>
	.front { position: relative; min-height: 100vh; overflow: hidden; }
	.space { position: absolute; inset: 0; }
	.veil { position: absolute; inset: 0; background: linear-gradient(90deg, rgba(11,13,19,0.86) 0%, rgba(11,13,19,0.55) 55%, rgba(11,13,19,0.2) 100%); pointer-events: none; }
	main { position: relative; max-width: 1240px; margin: 0 auto; padding: 60px 32px 40px; display: grid; grid-template-columns: 1.3fr 1fr; gap: 60px; align-items: start; min-height: calc(100vh - 120px); pointer-events: none; }
	main > * { pointer-events: auto; }
	.mark { height: 30px; width: auto; display: block; }
	h1 { font-size: 72px; margin: 28px 0 18px; }
	.tag { font-size: 16px; line-height: 1.6; max-width: 560px; margin: 0 0 28px; color: var(--fg-2); }
	.pins { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; max-width: 640px; }
	.psql { margin: 18px 0 0; font-size: 12px; }
	.login { padding: 26px 26px 28px; margin-top: 40px; }
	.login .lockup { margin-bottom: 18px; }
	.login .row { display: flex; gap: 10px; margin-top: 18px; align-items: center; flex-wrap: wrap; }
	.small { font-size: 12px; margin: 14px 0 0; }
	footer { position: relative; display: flex; gap: 40px; padding: 0 32px 32px; max-width: 1240px; margin: 0 auto; font-size: 13px; color: var(--fg-2); flex-wrap: wrap; }
	footer b { color: var(--fg); }
	footer a { color: var(--fg); text-decoration: underline; text-decoration-color: var(--fg-2); text-underline-offset: 3px; }
	footer a:hover { text-decoration-color: var(--fg); }
	footer .links { display: flex; gap: 18px; align-items: center; margin-left: auto; font-family: var(--font-head); font-weight: 600; font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; }
	footer .links a { display: inline-flex; align-items: center; gap: 6px; text-decoration: none; }
	footer .links a:hover { text-decoration: underline; }
	@media (max-width: 900px) { main { grid-template-columns: 1fr; gap: 32px; padding: 36px 20px; } h1 { font-size: 44px; } .pins { grid-template-columns: repeat(3, 1fr); gap: 8px; } .login { margin-top: 0; } }
</style>
