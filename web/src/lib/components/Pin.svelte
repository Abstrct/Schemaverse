<script lang="ts">
	// A trophy, mission or action card drawn in the language of the DEF CON 19
	// pins: paper, thick ink frame, the rotated-word lockup, the SQL that earns
	// it, an ink and steel illustration, the wordmark, a corner tag. Pins are
	// paper even when the interface is in the void; that is the point of them.
	import { shipSvg, PAPER_INKS } from '$lib/ship';
	export type Motif = 'ship' | 'fleet' | 'attack' | 'mine' | 'repair' | 'planet' | 'star' | 'peace' | 'course' | 'range' | 'listen' | 'locked';

	let {
		short, long, sql = '', description = '', motif = 'star', tag = '', won = false, dim = false, now = false, size = 'm', badge = ''
	}: { short: string; long: string; sql?: string; description?: string; motif?: Motif; tag?: string; won?: boolean; dim?: boolean; now?: boolean; size?: 's' | 'm' | 'l'; badge?: string } = $props();

	const INK = '#2e2f31', STEEL = '#516c9e';
	const ship = (x: number, y: number, s: number, rot = 0, flip = false) =>
		`<g transform="translate(${x},${y}) rotate(${rot}) scale(${flip ? -s : s},${s})">${shipSvg(PAPER_INKS)}</g>`;
	const spark = (x: number, y: number, s: number) => `<polygon fill="${STEEL}" transform="translate(${x},${y}) scale(${s})" points="0,-9 2,-2 9,0 2,2 0,9 -2,2 -9,0 -2,-2"/>`;
	const burst = (x: number, y: number, s: number) => `<polygon fill="${STEEL}" transform="translate(${x},${y}) scale(${s})" points="0,0 -9,-11 4,-6 7,-18 9,-5 21,-8 11,1 21,9 8,5 5,17 1,5 -12,7"/>`;
	const planet = (x: number, y: number, r: number) => `<circle fill="${INK}" cx="${x}" cy="${y}" r="${r}"/>`;
	const dots = `<circle fill="${STEEL}" cx="24" cy="18" r="3"/><circle fill="${STEEL}" cx="270" cy="30" r="2.5"/><circle fill="${STEEL}" cx="60" cy="110" r="2"/>`;

	const art = $derived.by(() => {
		switch (motif) {
			case 'ship': return ship(210, 70, 0.7) + spark(60, 50, 1.6);
			case 'fleet': return ship(150, 30, 0.42) + ship(220, 62, 0.42) + ship(140, 94, 0.42) + ship(270, 104, 0.3);
			case 'attack': return ship(110, 96, 0.45, -30) + ship(270, 36, 0.45, -30) + `<line x1="128" y1="86" x2="212" y2="52" stroke="${STEEL}" stroke-width="2"/>` + burst(214, 52, 1.1);
			case 'mine': return ship(230, 24, 0.5) + `<rect fill="${STEEL}" x="214" y="40" width="4" height="70"/><rect fill="${STEEL}" x="226" y="40" width="4" height="70"/><rect fill="${INK}" x="218" y="54" width="6" height="7"/><rect fill="${INK}" x="217" y="72" width="8" height="8"/><rect fill="${INK}" x="219" y="92" width="5" height="6"/><path fill="${INK}" d="M120,130 Q210,92 300,118 L300,130 Z"/>`;
			case 'repair': return ship(110, 30, 0.4) + ship(280, 100, 0.55) + `<line x1="122" y1="38" x2="248" y2="92" stroke="${STEEL}" stroke-width="3" stroke-dasharray="3 3"/>` + `<text fill="${STEEL}" x="150" y="52" font-family="Montserrat" font-weight="900" font-size="16">+</text><text fill="${STEEL}" x="180" y="72" font-family="Montserrat" font-weight="900" font-size="16">+</text>`;
			case 'planet': return `<path fill="${INK}" d="M80,130 Q200,40 300,90 L300,130 Z"/>` + planet(70, 40, 16) + ship(180, 40, 0.4) + ship(255, 20, 0.28);
			case 'peace': return `<circle fill="none" stroke="${STEEL}" stroke-width="3" cx="200" cy="70" r="46"/><circle fill="none" stroke="${STEEL}" stroke-width="1.5" cx="200" cy="70" r="40"/>` + ship(224, 76, 0.4) + ship(110, 30, 0.3) + ship(295, 120, 0.3);
			case 'course': return ship(100, 95, 0.45, -12) + `<line x1="150" y1="84" x2="250" y2="34" stroke="${STEEL}" stroke-width="2.5" stroke-dasharray="6 5"/>` + planet(262, 28, 18) + spark(50, 40, 1.4);
			case 'range': return ship(110, 60, 0.35) + ship(240, 100, 0.35, 0, true) + `<circle cx="110" cy="60" r="62" fill="none" stroke="${STEEL}" stroke-width="1.5" stroke-dasharray="2 4"/>`;
			case 'listen': return spark(90, 40, 1.8) + spark(230, 90, 2.4) + spark(170, 110, 0.9) + `<circle cx="230" cy="90" r="30" fill="none" stroke="${STEEL}" stroke-width="1" opacity="0.6"/><circle cx="230" cy="90" r="46" fill="none" stroke="${STEEL}" stroke-width="1" opacity="0.35"/>`;
			case 'locked': return ship(220, 70, 0.5) + `<rect x="60" y="30" width="80" height="80" fill="none" stroke="${STEEL}" stroke-width="2" stroke-dasharray="4 4"/>`;
			default: return spark(90, 40, 2.2) + spark(250, 90, 1.4) + ship(210, 50, 0.5);
		}
	});
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
