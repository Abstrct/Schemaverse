import type { RequestHandler } from '@sveltejs/kit';
import { spectatorEnabled } from '$lib/server/spectator';
import { sitemapEntries } from '$lib/server/public';

// The front door plus every public page: standings, profiles, shared
// scripts, rounds. The public pages exist only when the spectator role is
// configured, so without it the sitemap is just the front door.
export const GET: RequestHandler = async ({ url }) => {
	const paths: { p: string; f: string }[] = [{ p: '/', f: 'weekly' }];
	if (spectatorEnabled()) {
		try {
			const e = await sitemapEntries();
			paths.push({ p: '/players', f: 'hourly' }, { p: '/fleets', f: 'daily' }, { p: '/replays', f: 'daily' });
			for (const u of e.players) paths.push({ p: `/player/${u}`, f: 'daily' });
			for (const id of e.fleets) paths.push({ p: `/fleet/${id}`, f: 'weekly' });
			for (const r of e.rounds) paths.push({ p: `/replay/${r}`, f: 'monthly' });
		} catch {
			/* the database is away; the front door is still true */
		}
	}
	const urls = paths.map(({ p, f }) => `  <url><loc>${url.origin}${p}</loc><changefreq>${f}</changefreq></url>`).join('\n');
	const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`;
	return new Response(xml, { headers: { 'content-type': 'application/xml; charset=utf-8', 'cache-control': 'public, max-age=600' } });
};
