<script lang="ts">
	// The shell: a slim bar with the wordmark, the tabs, the clock and the
	// balances, then whatever page is open, full bleed. Notices from the
	// player's NOTIFY channel float in the corner.
	import { onMount, onDestroy } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { game } from '$lib/game.svelte';
	let { children } = $props();
	let ready = $state(false);
	let theme = $state<'dark' | 'light'>('dark');
	onMount(async () => {
		try { theme = (localStorage.getItem('theme') as 'dark' | 'light') || 'dark'; } catch {}
		document.documentElement.dataset.theme = theme;
		if (!(await game.refresh())) return goto('/');
		game.connect();
		ready = true;
	});
	onDestroy(() => game.disconnect());
	function toggleTheme() {
		theme = theme === 'dark' ? 'light' : 'dark';
		document.documentElement.dataset.theme = theme;
		try { localStorage.setItem('theme', theme); } catch {}
	}
	const tabs = [
		{ href: '/play/map', label: 'Map' },
		{ href: '/play', label: 'Console' },
		{ href: '/play/fleets', label: 'Fleets' },
		{ href: '/play/missions', label: 'Academy' },
		{ href: '/play/trophies', label: 'Trophies' },
		{ href: '/play/replay', label: 'Replay' }
	];
	const fmt = (n: number | string | undefined) => {
		if (n === undefined) return '';
		const v = Number(n);
		return v >= 1e6 ? (v / 1e6).toFixed(2) + 'M' : v.toLocaleString();
	};
	let latest = $derived(game.notices.slice(0, 3));
</script>

<div class="shell">
	<header>
		<a href="/play/map" class="logo"><img src={theme === 'dark' ? '/brand/wordmark-light.svg' : '/brand/wordmark.svg'} alt="Schemaverse" /></a>
		<nav>
			{#each tabs as t (t.href)}
				<a href={t.href} class:active={page.url.pathname === t.href}>{t.label}</a>
			{/each}
		</nav>
		{#if game.me}
			<div class="stats">
				<div class="stat"><small>Tic</small><b>{game.tic}</b></div>
				<div class="stat"><small>Round</small><b>{game.me.round}</b></div>
				<div class="stat"><small>Balance</small><b>{fmt(game.me.balance)}</b></div>
				<div class="stat"><small>Fuel</small><b>{fmt(game.me.fuel_reserve)}</b></div>
				<div class="stat"><small>Ships</small><b>{fmt(game.me.ships)}</b></div>
				<div class="stat"><small>Planets</small><b>{fmt(game.me.planets)}</b></div>
			</div>
			<div class="who">
				<span class="dot" class:on={game.connected} title={game.connected ? 'live' : 'reconnecting'}></span>
				<span class="mono">{game.me.username}</span>
				<button class="btn quiet small" onclick={toggleTheme} title="theme">{theme === 'dark' ? 'Paper' : 'Void'}</button>
				<button class="btn quiet small" onclick={() => game.logout().then(() => goto('/'))}>Log out</button>
			</div>
		{/if}
	</header>

	{#if ready}
		<main>{@render children()}</main>
	{:else}
		<main class="muted wait">Opening a connection as you…</main>
	{/if}

	<div class="toasts">
		{#each latest as n (n.at + n.payload)}
			<div class="toast hud" class:tic={n.kind === 'tic'}><span class="label">{n.channel === 'tic' ? 'tic' : 'notice'}</span>{n.payload}</div>
		{/each}
	</div>
</div>

<style>
	.shell { display: flex; flex-direction: column; height: 100vh; }
	header { display: flex; align-items: center; gap: 28px; padding: 0 20px; height: 56px; flex-shrink: 0; border-bottom: 1px solid var(--border); background: var(--bg); }
	.logo img { display: block; height: 24px; width: auto; }
	nav { display: flex; gap: 20px; height: 100%; }
	nav a { display: inline-flex; align-items: center; font-weight: 700; text-transform: uppercase; letter-spacing: 0.16em; font-size: 11px; color: var(--fg-2); padding: 0 2px; box-shadow: inset 0 -3px 0 transparent; }
	nav a:hover { color: var(--fg); }
	nav a.active { color: var(--fg); box-shadow: inset 0 -3px 0 var(--accent); }
	.stats { display: flex; gap: 20px; margin-left: auto; }
	.who { display: flex; align-items: center; gap: 10px; font-size: 12px; }
	main { flex: 1; min-height: 0; position: relative; display: flex; flex-direction: column; }
	.wait { padding: 24px; }
	.toasts { position: fixed; right: 20px; bottom: 20px; display: flex; flex-direction: column; gap: 6px; z-index: 50; max-width: 460px; }
	.toast { padding: 10px 14px; font-family: var(--font-mono); font-size: 12px; display: flex; flex-direction: column; gap: 2px; }
	.toast.tic { display: none; }
	@media (max-width: 1100px) { .stats { display: none; } }
	@media (max-width: 720px) { header { gap: 12px; padding: 0 12px; overflow-x: auto; } nav { gap: 12px; } .who .mono { display: none; } }
</style>
