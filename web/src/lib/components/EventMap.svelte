<script lang="ts">
	// The public events of a round on one plane: every attack, conquest and
	// loss with a location, plus the planets if the round is still on. Plain
	// SVG so it renders on the server and in a crawler; a tic scrubs it.
	type Pt = { tic: number; action: string; x: number; y: number; p1: number | null };
	type Pl = { id: number; name: string; x: number; y: number; conqueror_id: number | null };
	let { points, planets = [], bounds, tic }: { points: Pt[]; planets?: Pl[]; bounds: { min_x: number; max_x: number; min_y: number; max_y: number } | null; tic: number } = $props();
	const pad = 0.06;
	const box = $derived.by(() => {
		if (!bounds) return { x: -1e6, y: -1e6, w: 2e6, h: 2e6 };
		const w = Math.max(1, bounds.max_x - bounds.min_x), h = Math.max(1, bounds.max_y - bounds.min_y);
		const s = Math.max(w, h) || 1;
		return { x: bounds.min_x - s * pad, y: bounds.min_y - s * pad, w: w + 2 * s * pad, h: h + 2 * s * pad };
	});
	const r = $derived(Math.max(box.w, box.h) / 220);
	const color: Record<string, string> = { ATTACK: '#e06a5e', CONQUER: '#8fb0ff', EXPLODE: '#e3e5ec' };
</script>

<svg class="map" viewBox="{box.x} {-box.y - box.h} {box.w} {box.h}" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Map of public events this round">
	{#if !points.length && !planets.length}
		<text x={box.x + box.w / 2} y={-box.y - box.h / 2} text-anchor="middle" fill="#9c9da3" font-family="JetBrains Mono, monospace" font-size={box.w / 60}>no public event carried a location this round</text>
	{/if}
	<g transform="scale(1,-1)">
		{#each planets as p (p.id)}
			<circle cx={p.x} cy={p.y} r={r * 1.6} fill={p.conqueror_id ? '#7d96cc' : '#262a38'} stroke="#9c9da3" stroke-width={r * 0.3}><title>{p.name}</title></circle>
		{/each}
		{#each points as e, i (i)}
			{#if e.tic <= tic}
				<circle cx={e.x} cy={e.y} r={e.tic > tic - 5 ? r * 2.2 : r * 0.9} fill={color[e.action] ?? '#9c9da3'} opacity={e.tic > tic - 5 ? 1 : 0.55} />
			{/if}
		{/each}
	</g>
</svg>

<style>
	.map { width: 100%; height: auto; aspect-ratio: 16 / 9; display: block; background: var(--void); border: 1px solid var(--border); }
</style>
