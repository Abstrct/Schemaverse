<script lang="ts">
	// The public side of the game: what anyone can see without a login. A
	// slim header, the page, and the same footer as the front door.
	import { page } from '$app/state';
	import type { Snippet } from 'svelte';
	import type { LayoutData } from './$types';
	let { children, data }: { children: Snippet; data: LayoutData } = $props();
	const tabs = [
		{ href: '/players', label: 'Players' },
		{ href: '/fleets', label: 'Scripts' },
		{ href: '/replays', label: 'Replays' }
	];
	const active = (href: string) => page.url.pathname === href || page.url.pathname.startsWith(href.replace(/s$/, '/'));
</script>

<div class="pub">
	<header>
		<a href="/" class="logo"><img src="/brand/wordmark-light.svg" alt="Schemaverse" width="85" height="24" /></a>
		<nav>
			{#each tabs as t (t.href)}<a href={t.href} class:active={active(t.href)}>{t.label}</a>{/each}
		</nav>
		<span class="grow"></span>
		{#if data.me}
			<a class="btn quiet small" href="/player/{data.me.username}">My profile</a>
			<a class="btn primary small" href="/play/map">Play</a>
		{:else}
			<a class="btn primary small" href="/">Play</a>
		{/if}
	</header>
	<main>{@render children()}</main>
	<footer>
		<span><b>Everything here is a query.</b> Profiles read <span class="mono">trophy_case</span>, scripts read <span class="mono">shared_fleets</span>, replays read <span class="mono">event_archive</span>. Try them from psql.</span>
		<span class="links"><a href="https://github.com/abstrct/schemaverse">Source</a><a href="https://github.com/abstrct/schemaverse/blob/master/docs/PLAYING.md">How to play</a></span>
	</footer>
</div>

<style>
	.pub { min-height: 100vh; display: flex; flex-direction: column; }
	header { display: flex; align-items: center; gap: 28px; padding: 0 24px; height: 56px; border-bottom: 1px solid var(--border); background: var(--bg); position: sticky; top: 0; z-index: 5; }
	.logo img { display: block; height: 24px; width: auto; }
	nav { display: flex; gap: 20px; height: 100%; }
	nav a { display: inline-flex; align-items: center; font-weight: 700; text-transform: uppercase; letter-spacing: 0.16em; font-size: 11px; color: var(--fg-2); box-shadow: inset 0 -3px 0 transparent; }
	nav a:hover { color: var(--fg); }
	nav a.active { color: var(--fg); box-shadow: inset 0 -3px 0 var(--accent); }
	.grow { flex: 1; }
	main { flex: 1; width: 100%; max-width: 1180px; margin: 0 auto; padding: 36px 24px 60px; box-sizing: border-box; }
	footer { display: flex; gap: 32px; flex-wrap: wrap; padding: 24px; max-width: 1180px; margin: 0 auto; width: 100%; box-sizing: border-box; font-size: 13px; color: var(--fg-2); border-top: 1px solid var(--border); }
	footer b { color: var(--fg); }
	footer .links { display: flex; gap: 18px; margin-left: auto; font-family: var(--font-head); font-weight: 600; font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; }
	footer .links a { color: var(--fg); }
	@media (max-width: 720px) { header { gap: 14px; padding: 0 14px; overflow-x: auto; } nav { gap: 12px; } main { padding: 20px 14px 40px; } footer .links { margin-left: 0; } }
</style>
