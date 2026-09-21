// SVG in, PNG out, for link-preview cards. resvg renders offline with the
// bundled fonts, so a card looks the same on every server.
import { Resvg } from '@resvg/resvg-js';
import { fontFiles } from './fonts';

export function renderPng(svg: string, width = 1200): Uint8Array<ArrayBuffer> {
	const r = new Resvg(svg, {
		fitTo: { mode: 'width', value: width },
		font: { loadSystemFonts: false, fontFiles: fontFiles(), defaultFontFamily: 'Montserrat' }
	});
	return new Uint8Array(r.render().asPng());
}

export const PNG_HEADERS = { 'content-type': 'image/png', 'cache-control': 'public, max-age=300, s-maxage=300' };
