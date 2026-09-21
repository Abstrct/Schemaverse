// The illustrations on a pin, as SVG fragments in a 300 x 130 box. Drawn in
// the language of the DEF CON 19 pins: ink silhouettes, steel sparks, dashed
// steel beams. Used by the Pin component on screen and by the server when it
// draws a link-preview card, so a shared profile looks like the game.
import { shipSvg, PAPER_INKS } from '$lib/ship';

export type Motif = 'ship' | 'fleet' | 'attack' | 'mine' | 'repair' | 'planet' | 'star' | 'peace' | 'course' | 'range' | 'listen' | 'locked' | 'round' | 'script';

export const INK = '#2e2f31', STEEL = '#516c9e';
const ship = (x: number, y: number, s: number, rot = 0, flip = false) =>
	`<g transform="translate(${x},${y}) rotate(${rot}) scale(${flip ? -s : s},${s})">${shipSvg(PAPER_INKS)}</g>`;
const spark = (x: number, y: number, s: number) => `<polygon fill="${STEEL}" transform="translate(${x},${y}) scale(${s})" points="0,-9 2,-2 9,0 2,2 0,9 -2,2 -9,0 -2,-2"/>`;
const burst = (x: number, y: number, s: number) => `<polygon fill="${STEEL}" transform="translate(${x},${y}) scale(${s})" points="0,0 -9,-11 4,-6 7,-18 9,-5 21,-8 11,1 21,9 8,5 5,17 1,5 -12,7"/>`;
const planet = (x: number, y: number, r: number) => `<circle fill="${INK}" cx="${x}" cy="${y}" r="${r}"/>`;
export const dots = `<circle fill="${STEEL}" cx="24" cy="18" r="3"/><circle fill="${STEEL}" cx="270" cy="30" r="2.5"/><circle fill="${STEEL}" cx="60" cy="110" r="2"/>`;

/** The picture for a motif, without the background dots. */
export function artFor(motif: Motif): string {
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
		// a round: planets cut by the frame, a battle in the middle
		case 'round': return planet(40, 118, 34) + planet(290, 20, 30) + ship(150, 50, 0.4, -20) + ship(230, 95, 0.4, 160, false) + `<line x1="168" y1="58" x2="212" y2="86" stroke="${STEEL}" stroke-width="2"/>` + burst(214, 88, 0.9) + spark(100, 100, 1.3);
		// a script: a fleet flying in formation on rails
		case 'script': return `<line x1="40" y1="40" x2="300" y2="40" stroke="${STEEL}" stroke-width="1.5" stroke-dasharray="6 5"/><line x1="40" y1="75" x2="300" y2="75" stroke="${STEEL}" stroke-width="1.5" stroke-dasharray="6 5"/><line x1="40" y1="110" x2="300" y2="110" stroke="${STEEL}" stroke-width="1.5" stroke-dasharray="6 5"/>` + ship(120, 40, 0.34) + ship(190, 75, 0.34) + ship(260, 110, 0.34);
		default: return spark(90, 40, 2.2) + spark(250, 90, 1.4) + ship(210, 50, 0.5);
	}
}

/** Pick an illustration for a trophy from its name and description. */
export function trophyMotif(name: string, description: string): Motif {
	const s = (name + ' ' + description).toLowerCase();
	if (/attack|blood|damage|destroy|jerk|pillag/.test(s)) return 'attack';
	if (/repair|engineer/.test(s)) return 'repair';
	if (/peace/.test(s)) return 'peace';
	if (/mine|fuel|environment/.test(s)) return 'mine';
	if (/planet|conquer|emperor|empire|maintain/.test(s)) return 'planet';
	if (/fleet|ships|size|upgrade|powerful/.test(s)) return 'fleet';
	if (/distance|travel|explor|participat/.test(s)) return 'course';
	return 'ship';
}

/** Split a trophy name into the rotated short word and the big long word. */
export function splitName(name: string): [string, string] {
	const w = name.split(' ');
	if (w.length === 1) return ['THE', name];
	if (w.length === 2) return [w[0], w[1]];
	return [w[0], w.slice(1).join(' ')];
}
