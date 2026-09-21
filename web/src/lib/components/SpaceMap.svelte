<script lang="ts">
	// The map, drawn on a 2D canvas: nebula and stars with parallax, a faint
	// grid in world units, planets as lit spheres with craters and an owner
	// tint, particle streams for what ships are doing, and the pin ship rotated
	// to heading. Pan by dragging, zoom with the wheel. Clicks resolve to a
	// ship, a contact, a planet, or a point in space, and the page decides what
	// SQL that means.
	import { onMount } from 'svelte';
	import { drawShip } from '$lib/ship';
	import { playerColor, actionColor, ME_COLOR, type Snap, type Planet, type Ship, type Contact } from '$lib/types';

	export type Pick = { kind: 'ship'; ship: Ship } | { kind: 'contact'; contact: Contact } | { kind: 'planet'; planet: Planet } | { kind: 'space'; x: number; y: number };
	type Hover = { kind: 'ship' | 'contact' | 'planet'; id: number; text: string } | null;
	type Stream = { x1: number; y1: number; x2: number; y2: number; color: string; kind: 'mine' | 'attack' | 'repair' | 'course'; seed: number };

	let {
		snap = null,
		selected = null,
		cursor = 'grab',
		onpick,
		onhover
	}: { snap: Snap | null; selected?: number | null; cursor?: string; onpick?: (p: Pick) => void; onhover?: (h: Hover) => void } = $props();

	let host: HTMLDivElement;
	let canvas: HTMLCanvasElement;
	let ctx: CanvasRenderingContext2D;
	let W = 0, H = 0, dpr = 1;
	// the view: world centre and pixels per world unit
	let cx = 0, cy = 0, k = 0.0001;
	let kMin = 1e-6, kMax = 0.2;
	export const view = $state({ cx: 0, cy: 0, k: 0.0001, w: 0, h: 0, v: 0 });
	let hover = $state<Hover>(null);
	let streams: Stream[] = [];
	let raf = 0;
	let t0 = performance.now();

	// ---------- projection ----------
	export function project(x: number, y: number): [number, number] {
		return [(x - cx) * k + W / 2, H / 2 - (y - cy) * k];
	}
	function unproject(sx: number, sy: number): [number, number] {
		return [(sx - W / 2) / k + cx, cy - (sy - H / 2) / k];
	}
	function bump() { view.cx = cx; view.cy = cy; view.k = k; view.w = W; view.h = H; view.v++; }

	export function fit() {
		if (!snap || !W) return;
		const b = snap.bounds;
		const bw = Math.max(1, b.max_x - b.min_x), bh = Math.max(1, b.max_y - b.min_y);
		k = Math.min(W / bw, H / bh) * 0.86;
		kMin = k * 0.4;
		cx = (b.min_x + b.max_x) / 2; cy = (b.min_y + b.max_y) / 2;
		bump();
	}
	let anim: { fx: number; fy: number; fk: number; tx: number; ty: number; tk: number; start: number; ms: number } | null = null;
	export function flyTo(x: number, y: number, kk = 0.012, ms = 700) {
		anim = { fx: cx, fy: cy, fk: k, tx: x, ty: y, tk: Math.min(kMax, Math.max(kMin, kk)), start: performance.now(), ms };
	}
	/** Fly so that every point is on screen, with room around them. */
	export function fitPoints(pts: { x: number; y: number }[], ms = 700) {
		if (!pts.length || !W) return;
		const xs = pts.map((p) => p.x), ys = pts.map((p) => p.y);
		const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys);
		const bw = Math.max(1, maxX - minX), bh = Math.max(1, maxY - minY);
		// leave the bottom third for the HUD panel
		const kk = Math.min((W * 0.7) / bw, (H * 0.55) / bh, kMax);
		flyTo((minX + maxX) / 2, (minY + maxY) / 2 - (H * 0.12) / kk, kk, ms);
	}
	export function home() {
		if (!snap) return;
		const p = snap.planets.find((p) => p.conqueror_id === snap!.me.id) ?? snap.planets[0];
		if (p) flyTo(p.x, p.y, 0.02);
	}
	function stepAnim(now: number) {
		if (!anim) return;
		const t = Math.min(1, (now - anim.start) / anim.ms);
		const e = 1 - Math.pow(1 - t, 3);
		cx = anim.fx + (anim.tx - anim.fx) * e; cy = anim.fy + (anim.ty - anim.fy) * e;
		k = anim.fk * Math.pow(anim.tk / anim.fk, e);
		if (t >= 1) anim = null;
		bump();
	}

	// ---------- derived scene ----------
	function rebuild() {
		streams = [];
		if (!snap) return;
		const planets = new Map(snap.planets.map((p) => [p.id, p]));
		const ships = new Map(snap.ships.map((s) => [s.id, s]));
		const contacts = new Map(snap.contacts.map((c) => [c.id, c]));
		for (const s of snap.ships) {
			if (s.action === 'MINE' && s.action_target_id !== null) {
				const p = planets.get(s.action_target_id);
				if (p) streams.push({ x1: p.x, y1: p.y, x2: s.x, y2: s.y, color: ME_COLOR, kind: 'mine', seed: s.id });
			} else if (s.action === 'ATTACK' && s.action_target_id !== null) {
				const c = contacts.get(s.action_target_id);
				if (c) streams.push({ x1: s.x, y1: s.y, x2: c.x, y2: c.y, color: '#8fb0ff', kind: 'attack', seed: s.id });
			} else if (s.action === 'REPAIR' && s.action_target_id !== null) {
				const t = ships.get(s.action_target_id);
				if (t) streams.push({ x1: s.x, y1: s.y, x2: t.x, y2: t.y, color: ME_COLOR, kind: 'repair', seed: s.id });
			}
			if (s.destination_x !== null && s.destination_y !== null) {
				streams.push({ x1: s.x, y1: s.y, x2: s.destination_x, y2: s.destination_y, color: '#8fb0ff', kind: 'course', seed: s.id + 7919 });
			}
		}
	}
	$effect(() => { snap; rebuild(); if (snap && !fitted) { fitted = true; fit(); } });
	let fitted = false;

	// ---------- sprites ----------
	const spriteCache = new Map<string, HTMLCanvasElement>();
	function seeded(seed: number) {
		let s = (seed * 9301 + 49297) % 233280;
		return () => (s = (s * 9301 + 49297) % 233280) / 233280;
	}
	function sphere(id: number, r: number, tint: string | null): HTMLCanvasElement {
		const key = `${id}|${r}|${tint ?? ''}`;
		let c = spriteCache.get(key);
		if (c) return c;
		if (spriteCache.size > 3000) spriteCache.clear();
		const pad = 4, size = Math.ceil((r + pad) * 2);
		c = document.createElement('canvas');
		c.width = c.height = size;
		const g = c.getContext('2d')!;
		const o = r + pad;
		const grad = g.createRadialGradient(o - r * 0.32, o - r * 0.4, r * 0.05, o, o, r * 1.05);
		if (tint) {
			grad.addColorStop(0, '#f6f7fa'); grad.addColorStop(0.45, '#aeb2be'); grad.addColorStop(1, '#262934');
		} else {
			grad.addColorStop(0, '#9599a8'); grad.addColorStop(0.5, '#555968'); grad.addColorStop(1, '#14161d');
		}
		g.fillStyle = grad;
		g.beginPath(); g.arc(o, o, r, 0, Math.PI * 2); g.fill();
		if (r > 6) {
			const rnd = seeded(id);
			const n = Math.max(2, Math.round(r / 7));
			for (let i = 0; i < n; i++) {
				const a = rnd() * Math.PI * 2, d = (0.12 + rnd() * 0.66) * r, cr = (0.08 + rnd() * 0.12) * r;
				const x = o + Math.cos(a) * d, y = o + Math.sin(a) * d;
				g.fillStyle = 'rgba(0,0,0,0.24)'; g.beginPath(); g.ellipse(x, y, cr, cr * 0.85, 0, 0, Math.PI * 2); g.fill();
				g.fillStyle = 'rgba(255,255,255,0.10)'; g.beginPath(); g.ellipse(x - cr * 0.28, y - cr * 0.28, cr * 0.65, cr * 0.55, 0, 0, Math.PI * 2); g.fill();
			}
		}
		if (tint) {
			g.globalCompositeOperation = 'source-atop';
			g.fillStyle = tint; g.globalAlpha = 0.3;
			g.beginPath(); g.arc(o, o, r, 0, Math.PI * 2); g.fill();
		}
		spriteCache.set(key, c);
		return c;
	}

	// ---------- background ----------
	type Blob = { x: number; y: number; r: number; c: string; a: number };
	let blobs: Blob[] = [];
	let stars: { x: number; y: number; r: number; a: number }[] = [];
	function makeBackground() {
		const rnd = seeded(snap?.round ?? 1);
		const cols = ['#2a3d7a', '#1c2a55', '#3b3f52', '#22304f', '#4a5f9e', '#2b2f3d'];
		blobs = Array.from({ length: 9 }, () => ({ x: rnd(), y: rnd(), r: 0.12 + rnd() * 0.22, c: cols[Math.floor(rnd() * cols.length)], a: 0.3 + rnd() * 0.22 }));
		stars = Array.from({ length: 420 }, () => ({ x: rnd(), y: rnd(), r: 0.4 + rnd() * 0.8, a: 0.2 + rnd() * 0.45 }));
	}
	function drawBackground() {
		ctx.fillStyle = '#0b0d13';
		ctx.fillRect(0, 0, W, H);
		const T = 2400; // parallax tile in pixels
		const ox = ((-cx * k * 0.06) % T + T) % T, oy = ((cy * k * 0.06) % T + T) % T;
		for (const b of blobs) {
			for (const dx of [-T, 0]) for (const dy of [-T, 0]) {
				const x = b.x * T + ox + dx, y = b.y * T + oy + dy, r = b.r * T;
				if (x + r < 0 || x - r > W || y + r < 0 || y - r > H) continue;
				const g = ctx.createRadialGradient(x, y, 0, x, y, r);
				g.addColorStop(0, hexA(b.c, b.a)); g.addColorStop(1, hexA(b.c, 0));
				ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2);
			}
		}
		const sx = ((-cx * k * 0.18) % T + T) % T, sy = ((cy * k * 0.18) % T + T) % T;
		ctx.fillStyle = '#7d96cc';
		for (const s of stars) {
			const x = (s.x * T + sx) % T, y = (s.y * T + sy) % T;
			if (x > W || y > H) continue;
			ctx.globalAlpha = s.a; ctx.beginPath(); ctx.arc(x, y, s.r, 0, Math.PI * 2); ctx.fill();
		}
		ctx.globalAlpha = 1;
		// grid in world units
		const target = 110 / k;
		const step = Math.pow(10, Math.floor(Math.log10(target))) * ([1, 2, 5, 10].find((m) => Math.pow(10, Math.floor(Math.log10(target))) * m >= target) ?? 10);
		const [x0, y1] = unproject(0, 0), [x1, y0] = unproject(W, H);
		ctx.strokeStyle = 'rgba(237,238,238,0.045)'; ctx.lineWidth = 1;
		ctx.beginPath();
		for (let x = Math.floor(x0 / step) * step; x <= x1; x += step) { const [sx2] = project(x, 0); ctx.moveTo(Math.round(sx2) + 0.5, 0); ctx.lineTo(Math.round(sx2) + 0.5, H); }
		for (let y = Math.floor(y0 / step) * step; y <= y1; y += step) { const [, sy2] = project(0, y); ctx.moveTo(0, Math.round(sy2) + 0.5); ctx.lineTo(W, Math.round(sy2) + 0.5); }
		ctx.stroke();
	}
	function hexA(hex: string, a: number) {
		const n = parseInt(hex.slice(1), 16);
		return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
	}

	// ---------- scene ----------
	const planetRadius = (p: Planet) => 1200 + p.mine_limit * 30;
	function planetPx(p: Planet) { return Math.min(64, Math.max(3, planetRadius(p) * k)); }
	function shipScale() { return Math.min(0.24, Math.max(0.028, (k / 0.004) * 0.12)); }
	function burst(x: number, y: number, s: number, color: string) {
		const pts = [[0, 0], [-9, -11], [4, -6], [7, -18], [9, -5], [21, -8], [11, 1], [21, 9], [8, 5], [5, 17], [1, 5], [-12, 7]];
		ctx.save(); ctx.translate(x, y); ctx.scale(s, s); ctx.fillStyle = color;
		ctx.beginPath(); ctx.moveTo(pts[0][0], pts[0][1]); for (const p of pts.slice(1)) ctx.lineTo(p[0], p[1]); ctx.closePath(); ctx.fill(); ctx.restore();
	}
	function drawStreams(now: number) {
		const t = (now - t0) / 1000;
		for (const s of streams) {
			const [ax, ay] = project(s.x1, s.y1), [bx, by] = project(s.x2, s.y2);
			if (Math.max(ax, bx) < -50 || Math.min(ax, bx) > W + 50 || Math.max(ay, by) < -50 || Math.min(ay, by) > H + 50) continue;
			const dx = bx - ax, dy = by - ay, L = Math.hypot(dx, dy);
			if (L < 4) continue;
			const nx = -dy / L, ny = dx / L;
			ctx.strokeStyle = s.color; ctx.globalAlpha = s.kind === 'attack' ? 0.5 : 0.18; ctx.lineWidth = s.kind === 'attack' ? 1.5 : 0.8;
			ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(bx, by); ctx.stroke();
			if (s.kind === 'attack') {
				ctx.globalAlpha = 0.16; ctx.lineWidth = 8; ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(bx, by); ctx.stroke();
				ctx.globalAlpha = 0.9; burst(bx, by, 0.9 + 0.2 * Math.sin(t * 9 + s.seed), s.color);
			}
			// particles are streaks along the flow, never discs, so they cannot be mistaken for a planet
			const n = Math.min(60, Math.max(5, Math.round(L / 11)));
			const rnd = seeded(s.seed);
			const speed = s.kind === 'course' ? 0.08 : 0.16;
			const ux = dx / L, uy = dy / L;
			ctx.strokeStyle = s.color; ctx.lineCap = 'round';
			for (let i = 0; i < n; i++) {
				const jit = (rnd() - 0.5) * 10, len = 3 + rnd() * 6, ph = rnd(), w = 0.6 + rnd() * 0.8;
				const u = (ph + t * speed) % 1;
				const env = Math.sin(u * Math.PI);
				const x = ax + dx * u + nx * jit * env, y = ay + dy * u + ny * jit * env;
				ctx.globalAlpha = 0.2 + 0.5 * env; ctx.lineWidth = w;
				ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + ux * len, y + uy * len); ctx.stroke();
			}
			ctx.lineCap = 'butt';
		}
		ctx.globalAlpha = 1;
	}
	function drawPlanets() {
		if (!snap) return;
		ctx.font = '10px "JetBrains Mono", monospace'; ctx.textAlign = 'center';
		for (const p of snap.planets) {
			const [x, y] = project(p.x, p.y);
			const r = planetPx(p);
			if (x < -r - 40 || x > W + r + 40 || y < -r - 40 || y > H + r + 40) continue;
			const tint = p.conqueror_id !== null ? playerColor(p.conqueror_id, snap.me.id) : null;
			if (tint && r > 4) {
				const g = ctx.createRadialGradient(x, y, r * 0.6, x, y, r * 1.8);
				g.addColorStop(0, hexA(tint, 0.3)); g.addColorStop(1, hexA(tint, 0));
				ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r * 1.8, 0, Math.PI * 2); ctx.fill();
			}
			if (r < 5) {
				// far away: a solid disc with a thin ring, the planet glyph of the star chart
				const rr = Math.max(3, r);
				ctx.fillStyle = tint ?? '#b9bcc7'; ctx.beginPath(); ctx.arc(x, y, rr, 0, Math.PI * 2); ctx.fill();
				ctx.strokeStyle = tint ?? '#b9bcc7'; ctx.globalAlpha = 0.55; ctx.lineWidth = 1;
				ctx.beginPath(); ctx.arc(x, y, rr + 2.5, 0, Math.PI * 2); ctx.stroke(); ctx.globalAlpha = 1;
				continue;
			}
			const rr = Math.round(r);
			const sp = sphere(p.id, rr, tint);
			ctx.drawImage(sp, x - sp.width / 2, y - sp.height / 2);
			if (r > 7) {
				ctx.fillStyle = tint ?? 'rgba(156,157,163,0.6)';
				const bw = tint ? r * 1.6 : r;
				ctx.fillRect(x - bw / 2, y + r + 7, bw, tint ? 3 : 2);
				if (r > 10) {
					ctx.fillStyle = tint ?? '#9c9da3';
					ctx.fillText(tint && p.conqueror ? `${p.conqueror.username} · ${p.name}` : p.name, x, y + r + 24);
				}
			}
			if (hover?.kind === 'planet' && hover.id === p.id) {
				ctx.strokeStyle = '#8fb0ff'; ctx.lineWidth = 1; ctx.setLineDash([3, 4]);
				ctx.beginPath(); ctx.arc(x, y, r + 6, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
			}
		}
	}
	const proj = (x: number, y: number) => { const [sx, sy] = project(x, y); return { x: sx, y: sy }; };
	function lead(wx: number, wy: number, x: number, y: number, col: string) {
		const [tx, ty] = project(wx, wy);
		if (Math.hypot(tx - x, ty - y) < 4) return;
		ctx.strokeStyle = col; ctx.globalAlpha = 0.45; ctx.lineWidth = 1;
		ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(x, y); ctx.stroke();
		ctx.fillStyle = col; ctx.beginPath(); ctx.arc(tx, ty, 1.5, 0, Math.PI * 2); ctx.fill();
		ctx.globalAlpha = 1;
	}
	function reticle(x: number, y: number, w: number, h: number, color: string) {
		const L = Math.min(12, w / 3);
		ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.beginPath();
		ctx.moveTo(x, y + L); ctx.lineTo(x, y); ctx.lineTo(x + L, y);
		ctx.moveTo(x + w - L, y); ctx.lineTo(x + w, y); ctx.lineTo(x + w, y + L);
		ctx.moveTo(x + w, y + h - L); ctx.lineTo(x + w, y + h); ctx.lineTo(x + w - L, y + h);
		ctx.moveTo(x + L, y + h); ctx.lineTo(x, y + h); ctx.lineTo(x, y + h - L);
		ctx.stroke();
	}
	// Ships that share a spot are spread on a small ring around it so each one
	// can be seen and clicked. A hairline leads back to the true position.
	let placed = new Map<string, [number, number]>();
	export function shipScreen(id: number): [number, number] | null { return placed.get('s' + id) ?? null; }
	function place(items: { key: string; x: number; y: number }[], sep: number) {
		const out = new Map<string, [number, number]>();
		const cell = Math.max(1, sep);
		const buckets = new Map<string, number[]>();
		items.forEach((it, i) => {
			const bk = `${Math.floor(it.x / cell)},${Math.floor(it.y / cell)}`;
			(buckets.get(bk) ?? buckets.set(bk, []).get(bk)!).push(i);
		});
		const seen = new Set<number>();
		items.forEach((it, i) => {
			if (seen.has(i)) return;
			// gather everything within sep of this one, through neighbouring cells
			const group: number[] = [];
			const cx0 = Math.floor(it.x / cell), cy0 = Math.floor(it.y / cell);
			for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++)
				for (const j of buckets.get(`${cx0 + dx},${cy0 + dy}`) ?? [])
					if (!seen.has(j) && Math.hypot(items[j].x - it.x, items[j].y - it.y) < sep) group.push(j);
			for (const j of group) seen.add(j);
			if (group.length === 1) { out.set(it.key, [it.x, it.y]); return; }
			group.sort((a, b) => (items[a].key < items[b].key ? -1 : 1));
			const gx = group.reduce((a, j) => a + items[j].x, 0) / group.length, gy = group.reduce((a, j) => a + items[j].y, 0) / group.length;
			const r = Math.max(sep * 0.8, (sep * group.length) / (2 * Math.PI));
			group.forEach((j, n) => {
				const a = (2 * Math.PI * n) / group.length - Math.PI / 2;
				out.set(items[j].key, [gx + Math.cos(a) * r, gy + Math.sin(a) * r]);
			});
		});
		return out;
	}
	function drawShips() {
		if (!snap) return;
		const s0 = shipScale();
		const len = 200 * s0;
		const items = [
			...snap.ships.map((s) => ({ key: 's' + s.id, ...proj(s.x, s.y) })),
			...snap.contacts.map((c) => ({ key: 'c' + c.id, ...proj(c.x, c.y) }))
		];
		placed = len < 9 ? new Map(items.map((it) => [it.key, [it.x, it.y] as [number, number]])) : place(items, len * 1.05);
		ctx.font = '10px "JetBrains Mono", monospace'; ctx.textAlign = 'left';
		for (const c of snap.contacts) {
			const [x, y] = placed.get('c' + c.id)!;
			if (x < -40 || x > W + 40 || y < -40 || y > H + 40) continue;
			const col = playerColor(c.player_id, snap.me.id);
			lead(c.x, c.y, x, y, col);
			if (len < 9) { ctx.fillStyle = col; ctx.fillRect(x - 1.5, y - 1.5, 3, 3); continue; }
			drawShip(ctx, x, y, s0 * 0.85, 0, { hull: '#d5d7de', steel: col, gap: '#0b0d13' });
			if (hover?.kind === 'contact' && hover.id === c.id) { ctx.fillStyle = col; ctx.fillText(`${c.player.username} · ${c.name}`, x + len / 2 + 6, y + 4); }
		}
		for (const s of snap.ships) {
			const [x, y] = placed.get('s' + s.id)!;
			if (x < -60 || x > W + 60 || y < -60 || y > H + 60) continue;
			const dead = s.current_health <= 0;
			const sel = selected === s.id;
			const col = dead ? '#d8534a' : actionColor(s.action, s.destination_x !== null);
			lead(s.x, s.y, x, y, col);
			if (len < 9) { ctx.fillStyle = col; ctx.fillRect(x - 1.5, y - 1.5, 3, 3); continue; }
			if (sel) {
				const [tx, ty] = project(s.x, s.y);
				ctx.strokeStyle = 'rgba(125,150,204,0.45)'; ctx.lineWidth = 1; ctx.setLineDash([2, 6]);
				ctx.beginPath(); ctx.arc(tx, ty, Math.max(12, s.range * k), 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
			}
			// a soft halo in the action colour, so a fleet reads at a glance
			if (!dead && (s.action || s.destination_x !== null)) {
				const g = ctx.createRadialGradient(x, y, len * 0.1, x, y, len * 0.55);
				g.addColorStop(0, hexA(col, 0.32)); g.addColorStop(1, hexA(col, 0));
				ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, len * 0.55, 0, Math.PI * 2); ctx.fill();
			}
			const angle = (-s.direction * Math.PI) / 180;
			drawShip(ctx, x, y, s0, angle, { hull: dead ? '#6a3b38' : '#ededee', steel: col, gap: '#0b0d13' });
			if (sel || (hover?.kind === 'ship' && hover.id === s.id)) {
				const bw = len + 16, bh = len * 0.5 + 16;
				reticle(x - bw / 2, y - bh / 2, bw, bh, '#8fb0ff');
				ctx.fillStyle = '#8fb0ff';
				ctx.fillText(`${s.name || '#' + s.id} · ${s.current_health}/${s.max_health} · fuel ${s.current_fuel}${s.action ? ' · ' + s.action : ''}`, x - bw / 2, y - bh / 2 - 8);
			}
		}
	}

	function frame(now: number) {
		raf = requestAnimationFrame(frame);
		if (!ctx || !W) return;
		stepAnim(now);
		ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
		drawBackground();
		drawStreams(now);
		drawPlanets();
		drawShips();
	}

	// ---------- input ----------
	let drag = $state<{ x: number; y: number; cx: number; cy: number; moved: boolean } | null>(null);
	function down(e: PointerEvent) {
		canvas.setPointerCapture(e.pointerId);
		drag = { x: e.clientX, y: e.clientY, cx, cy, moved: false };
	}
	function move(e: PointerEvent) {
		const rect = canvas.getBoundingClientRect();
		const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
		if (drag) {
			const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
			if (Math.hypot(dx, dy) > 4) drag.moved = true;
			if (drag.moved) { anim = null; cx = drag.cx - dx / k; cy = drag.cy + dy / k; bump(); }
			return;
		}
		const h = hit(sx, sy);
		const changed = (h?.kind ?? null) !== (hover?.kind ?? null) || h?.id !== hover?.id;
		hover = h;
		if (changed) onhover?.(h);
	}
	function up(e: PointerEvent) {
		if (!drag) return;
		const wasDrag = drag.moved;
		drag = null;
		if (wasDrag) return;
		const rect = canvas.getBoundingClientRect();
		const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
		const h = hit(sx, sy);
		if (!snap) return;
		if (h?.kind === 'ship') onpick?.({ kind: 'ship', ship: snap.ships.find((s) => s.id === h.id)! });
		else if (h?.kind === 'contact') onpick?.({ kind: 'contact', contact: snap.contacts.find((c) => c.id === h.id)! });
		else if (h?.kind === 'planet') onpick?.({ kind: 'planet', planet: snap.planets.find((p) => p.id === h.id)! });
		else { const [x, y] = unproject(sx, sy); onpick?.({ kind: 'space', x: Math.round(x), y: Math.round(y) }); }
	}
	function wheel(e: WheelEvent) {
		e.preventDefault();
		anim = null;
		const rect = canvas.getBoundingClientRect();
		const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
		const [wx, wy] = unproject(sx, sy);
		const f = Math.pow(1.0015, -e.deltaY);
		k = Math.min(kMax, Math.max(kMin, k * f));
		// keep the point under the cursor fixed
		cx = wx - (sx - W / 2) / k; cy = wy + (sy - H / 2) / k;
		bump();
	}
	function hit(sx: number, sy: number): Hover {
		if (!snap) return null;
		const len = 200 * shipScale();
		const rr = Math.max(10, len / 2);
		let best: Hover = null, bd = 1e9;
		for (const s of snap.ships) {
			const [x, y] = placed.get('s' + s.id) ?? project(s.x, s.y); const d = Math.hypot(x - sx, y - sy);
			if (d < rr && d < bd) { bd = d; best = { kind: 'ship', id: s.id, text: `${s.name || '#' + s.id} · ${s.current_health}/${s.max_health} hp · fuel ${s.current_fuel} · ${s.action ?? 'idle'}` }; }
		}
		if (best) return best;
		for (const c of snap.contacts) {
			const [x, y] = placed.get('c' + c.id) ?? project(c.x, c.y); const d = Math.hypot(x - sx, y - sy);
			if (d < rr && d < bd) { bd = d; best = { kind: 'contact', id: c.id, text: `${c.player.username}'s ${c.name} · health ${Math.round(Number(c.health) * 100)}%` }; }
		}
		if (best) return best;
		for (const p of snap.planets) {
			const [x, y] = project(p.x, p.y); const d = Math.hypot(x - sx, y - sy);
			if (d < planetPx(p) + 6 && d < bd) { bd = d; best = { kind: 'planet', id: p.id, text: `${p.name} · planet ${p.id} · mine limit ${p.mine_limit}${p.conqueror ? ' · ' + p.conqueror.username : ' · unclaimed'}` }; }
		}
		return best;
	}

	onMount(() => {
		ctx = canvas.getContext('2d')!;
		makeBackground();
		const ro = new ResizeObserver(() => {
			dpr = window.devicePixelRatio || 1;
			W = host.clientWidth; H = host.clientHeight;
			canvas.width = W * dpr; canvas.height = H * dpr;
			canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
			if (!fitted && snap) { fitted = true; fit(); }
			bump();
		});
		ro.observe(host);
		raf = requestAnimationFrame(frame);
		return () => { ro.disconnect(); cancelAnimationFrame(raf); };
	});
</script>

<div bind:this={host} class="host" style="cursor: {drag?.moved ? 'grabbing' : hover ? 'pointer' : cursor}">
	<canvas bind:this={canvas} onpointerdown={down} onpointermove={move} onpointerup={up} onpointercancel={() => (drag = null)} onwheel={wheel}></canvas>
</div>

<style>
	.host { position: absolute; inset: 0; overflow: hidden; background: #0b0d13; }
	canvas { display: block; touch-action: none; }
</style>
