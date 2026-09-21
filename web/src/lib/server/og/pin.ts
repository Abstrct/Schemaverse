// A pin as a 1200 x 630 SVG: the paper card the game already draws for
// trophies, sized for a link preview. Same ink, same lockup, same art. The
// page shows the identical SVG inline, so what a visitor sees on the site is
// what a chat unfurl shows.
import wordmark from '../../../../static/brand/wordmark.svg?raw';
import { artFor, dots, INK, STEEL, type Motif } from '$lib/pinart';

const PAPER = '#f7f7f5', INK2 = '#6a6b70';
const W = 1200, H = 630;
const HEAD = `font-family="Montserrat"`, MONO = `font-family="JetBrains Mono"`;

export const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** Wrap at a character budget, at most n lines, last line ellipsised. */
export function wrap(text: string, chars: number, lines: number): string[] {
	const out: string[] = [];
	for (const raw of text.split('\n')) {
		let line = '';
		for (const w of raw.split(/\s+/)) {
			if (!w) continue;
			if ((line + ' ' + w).trim().length > chars && line) { out.push(line); line = w; } else line = (line + ' ' + w).trim();
		}
		if (line) out.push(line);
	}
	if (out.length > lines) { out.length = lines; out[lines - 1] = out[lines - 1].slice(0, chars - 1) + '…'; }
	return out;
}

export type Stat = { label: string; value: string };
export type PinCard = {
	short: string; long: string; sql?: string; description?: string; motif?: Motif;
	tag?: string; badge?: string; stats?: Stat[]; code?: string[];
};

const wm = wordmark.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');

export function pinSvg(c: PinCard): string {
	const long = c.long.toUpperCase();
	// Montserrat 900 caps run about 0.78 em wide; fit the long word to the card.
	const L = Math.max(64, Math.min(168, Math.floor(700 / (long.length * 0.78))));
	const top = 76, base = top + L * 0.74;
	let y = base + 56;
	let body = '';
	if (c.sql) {
		for (const line of wrap(c.sql, 60, 2)) { body += `<text x="112" y="${y}" ${MONO} font-size="24" fill="${INK}">${esc(line)}</text>`; y += 32; }
		y += 6;
	}
	if (c.description) {
		for (const line of wrap(c.description, 64, 2)) { body += `<text x="112" y="${y}" ${HEAD} font-weight="700" font-size="22" fill="${INK2}">${esc(line)}</text>`; y += 30; }
	}
	if (c.code?.length) {
		const lines = c.code.slice(0, 5);
		body += `<rect x="112" y="${y - 6}" width="560" height="${lines.length * 26 + 20}" fill="#ededeb"/>`;
		let cy = y + 20;
		for (const line of lines) { body += `<text x="126" y="${cy}" ${MONO} font-size="17" fill="${INK}">${esc(line.length > 52 ? line.slice(0, 51) + '…' : line)}</text>`; cy += 26; }
	}
	let stats = '';
	(c.stats ?? []).slice(0, 4).forEach((s, i) => {
		const x = 112 + i * 168;
		stats += `<text x="${x}" y="${H - 132}" ${HEAD} font-weight="900" font-size="44" letter-spacing="-1.5" fill="${INK}">${esc(s.value)}</text>`;
		stats += `<text x="${x}" y="${H - 104}" ${HEAD} font-weight="700" font-size="11" letter-spacing="2" fill="${INK2}">${esc(s.label.toUpperCase())}</text>`;
	});
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<rect width="${W}" height="${H}" fill="${PAPER}"/>
<rect x="7" y="7" width="${W - 14}" height="${H - 14}" fill="none" stroke="${INK}" stroke-width="14"/>
<g transform="translate(750,236) scale(1.9)">${dots}${artFor(c.motif ?? 'star')}</g>
<text transform="translate(${88},${base}) rotate(-90)" ${HEAD} font-weight="700" font-size="28" letter-spacing="0.5" fill="${INK}">${esc(c.short.toUpperCase())}</text>
<text x="112" y="${base}" ${HEAD} font-weight="900" font-size="${L}" letter-spacing="${-L * 0.04}" fill="${INK}">${esc(long)}</text>
${body}${stats}
<g transform="translate(64,${H - 76}) scale(0.36) translate(-170,-579)">${wm}</g>
${c.tag ? `<text x="${W - 64}" y="${H - 52}" text-anchor="end" ${HEAD} font-weight="700" font-size="20" letter-spacing="2" fill="${INK}">${esc(c.tag.toUpperCase())}</text>` : ''}
${c.badge ? `<text x="${W - 64}" y="${76}" text-anchor="end" ${HEAD} font-weight="700" font-size="18" letter-spacing="3" fill="${STEEL}">${esc(c.badge.toUpperCase())}</text>` : ''}
</svg>`;
}
