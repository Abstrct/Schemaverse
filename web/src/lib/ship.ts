// The pin ship. Traced from the DEF CON 19 "attack" and "mine" pins: a long
// wedge hull with a raised rear deck, two slanted cockpit panels on the shelf,
// a split engine block with two rows of three stripes, and a lower slab with
// a keel. Local space is 200 x 70 with the nose at +x, origin at the centre,
// so a heading of 0 degrees flies along +x.
//
// One geometry, two renderers: Canvas 2D for the map, SVG for pins and cards.

export type ShipInks = { hull: string; steel: string; gap: string };

// Polygons in the pin's own orientation (nose to the left), mirrored below.
const UPPER = [[0, 47], [23, 18], [94, 18], [113, 0], [167, 0], [167, 48]];
const LOWER = [[44, 50], [199, 50], [199, 68], [118, 68], [86, 58]];
const PANEL_A = [[52, 9], [65, 9], [62, 17], [49, 17]];
const PANEL_B = [[70, 9], [99, 9], [95, 17], [67, 17]];
const BLOCK = { x: 167, y: 0, w: 32, h: 48 };
const STRIPES = [0, 1, 2].map((i) => 183 + i * 5.5);

// Mirror to nose-right and centre on (0,0).
const mx = (x: number) => 100 - x;
const my = (y: number) => y - 35;
const P = (pts: number[][]) => pts.map(([x, y]) => [mx(x), my(y)] as [number, number]);
export const GEOM = {
	upper: P(UPPER),
	lower: P(LOWER),
	panels: [P(PANEL_A), P(PANEL_B)],
	block: { x: mx(BLOCK.x + BLOCK.w), y: my(BLOCK.y), w: BLOCK.w, h: BLOCK.h },
	blockSplitX: mx(179),
	blockSplitY: my(25),
	stripes: STRIPES.map((x) => ({ x: mx(x + 3.5), w: 3.5 })),
	gapY: my(48.5),
	length: 200,
	height: 70
};

function poly(ctx: CanvasRenderingContext2D, pts: [number, number][]) {
	ctx.beginPath();
	ctx.moveTo(pts[0][0], pts[0][1]);
	for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
	ctx.closePath();
	ctx.fill();
}

/**
 * Draw a ship on a canvas. `scale` is pixels per local unit (a scale of 0.13
 * draws a 26 px ship). `angle` is the heading in radians, counter-clockwise
 * in a y-up world; pass the screen-space angle you want.
 */
export function drawShip(ctx: CanvasRenderingContext2D, x: number, y: number, scale: number, angle: number, inks: ShipInks) {
	ctx.save();
	ctx.translate(x, y);
	ctx.rotate(angle);
	ctx.scale(scale, scale);
	ctx.fillStyle = inks.hull;
	poly(ctx, GEOM.lower);
	poly(ctx, GEOM.upper);
	ctx.fillRect(GEOM.block.x, GEOM.block.y, GEOM.block.w, GEOM.block.h);
	// gaps: the paper between the hulls and inside the engine block
	ctx.strokeStyle = inks.gap;
	ctx.lineWidth = 2;
	ctx.beginPath();
	ctx.moveTo(-100, GEOM.gapY); ctx.lineTo(100, GEOM.gapY);
	ctx.stroke();
	ctx.lineWidth = 1.5;
	ctx.beginPath();
	ctx.moveTo(GEOM.blockSplitX, GEOM.block.y); ctx.lineTo(GEOM.blockSplitX, GEOM.block.y + GEOM.block.h);
	ctx.moveTo(GEOM.block.x, GEOM.blockSplitY); ctx.lineTo(GEOM.block.x + GEOM.block.w, GEOM.blockSplitY);
	ctx.stroke();
	ctx.fillStyle = inks.steel;
	for (const p of GEOM.panels) poly(ctx, p);
	for (const s of GEOM.stripes) {
		ctx.fillRect(s.x, my(2), s.w, 21);
		ctx.fillRect(s.x, my(27), s.w, 19);
	}
	ctx.restore();
}

const pts = (p: [number, number][]) => p.map(([x, y]) => `${x},${y}`).join(' ');

/** The same ship as an SVG fragment, for pins and cards. Wrap in a <g transform>. */
export function shipSvg(inks: ShipInks): string {
	return (
		`<polygon fill="${inks.hull}" points="${pts(GEOM.lower)}"/>` +
		`<polygon fill="${inks.hull}" points="${pts(GEOM.upper)}"/>` +
		`<rect fill="${inks.hull}" x="${GEOM.block.x}" y="${GEOM.block.y}" width="${GEOM.block.w}" height="${GEOM.block.h}"/>` +
		`<line x1="-100" y1="${GEOM.gapY}" x2="100" y2="${GEOM.gapY}" stroke="${inks.gap}" stroke-width="2"/>` +
		`<line x1="${GEOM.blockSplitX}" y1="${GEOM.block.y}" x2="${GEOM.blockSplitX}" y2="${GEOM.block.y + GEOM.block.h}" stroke="${inks.gap}" stroke-width="1.5"/>` +
		`<line x1="${GEOM.block.x}" y1="${GEOM.blockSplitY}" x2="${GEOM.block.x + GEOM.block.w}" y2="${GEOM.blockSplitY}" stroke="${inks.gap}" stroke-width="1.5"/>` +
		GEOM.panels.map((p) => `<polygon fill="${inks.steel}" points="${pts(p)}"/>`).join('') +
		GEOM.stripes.map((s) => `<rect fill="${inks.steel}" x="${s.x}" y="${my(2)}" width="${s.w}" height="21"/><rect fill="${inks.steel}" x="${s.x}" y="${my(27)}" width="${s.w}" height="19"/>`).join('')
	);
}

export const PAPER_INKS: ShipInks = { hull: '#2e2f31', steel: '#516c9e', gap: '#f7f7f5' };
export const VOID_INKS: ShipInks = { hull: '#ededee', steel: '#7d96cc', gap: '#0b0d13' };
