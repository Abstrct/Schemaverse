<script lang="ts">
	// A trophy, mission or action card drawn in the language of the DEF CON 19
	// pins: paper, thick ink frame, the rotated-word lockup, the SQL that earns
	// it, an ink and steel illustration, the wordmark, a corner tag. Pins are
	// paper even when the interface is in the void; that is the point of them.
	import { artFor, dots, type Motif } from '$lib/pinart';

	let {
		short, long, sql = '', description = '', motif = 'star', tag = '', won = false, dim = false, now = false, size = 'm', badge = ''
	}: { short: string; long: string; sql?: string; description?: string; motif?: Motif; tag?: string; won?: boolean; dim?: boolean; now?: boolean; size?: 's' | 'm' | 'l'; badge?: string } = $props();

	const art = $derived(artFor(motif));
	const longSize = $derived(long.length > 14 ? 0.5 : long.length > 10 ? 0.62 : long.length > 7 ? 0.78 : 1);
</script>

<div class="pin size-{size}" class:won class:dim class:now style="--k: {longSize}">
	{#if badge}<span class="badge" class:steel={won || now}>{badge}</span>{/if}
	<div class="lockup">
		<span class="short">{short}</span>
		<span class="long">{long}</span>
	</div>
	{#if sql}<p class="sql">{sql}</p>{/if}
	{#if description}<p class="desc">{description}</p>{/if}
	<svg class="art" viewBox="0 0 300 130" aria-hidden="true">{@html dots + art}</svg>
	<img class="wordmark" src="/brand/wordmark.svg" alt="Schemaverse" />
	{#if tag}<span class="tag">{tag}</span>{/if}
</div>

<style>
	.pin {
		aspect-ratio: 3 / 2; position: relative; overflow: hidden;
		background: var(--paper); color: var(--ink); border: 3px solid var(--ink);
		display: flex; flex-direction: column; container-type: inline-size;
		padding: 5.5cqw 5cqw 10cqw;
	}
	.pin.won { outline: 4px solid var(--steel); outline-offset: -4px; }
	.pin.now { border-color: var(--steel); }
	.pin.dim { opacity: 0.5; }
	.lockup { gap: 2cqw; }
	.lockup .short { font-size: 4.6cqw; color: var(--ink); }
	.lockup .long { font-size: calc(15cqw * var(--k)); color: var(--ink); }
	.sql { font-family: var(--font-mono); font-size: 2.7cqw; margin: 2.5cqw 0 0; color: var(--ink); position: relative; z-index: 1; max-width: 62%; line-height: 1.45; word-break: break-word; }
	.desc { font-size: 3cqw; margin: 1.5cqw 0 0; position: relative; z-index: 1; max-width: 60%; color: var(--ink-2); font-weight: 500; }
	.art { position: absolute; right: 0; bottom: 0; width: 64%; height: 58%; }
	.wordmark { position: absolute; left: 5cqw; bottom: 3cqw; height: 4.4cqw; width: auto; }
	.tag { position: absolute; right: 3cqw; bottom: 1.8cqw; font-weight: 500; font-size: 2.6cqw; letter-spacing: 0.08em; color: var(--ink); }
	.badge { position: absolute; right: 3cqw; top: 2.5cqw; font-weight: 700; font-size: 2.4cqw; letter-spacing: 0.16em; text-transform: uppercase; color: var(--ink-2); }
	.badge.steel { color: var(--steel); }
</style>
