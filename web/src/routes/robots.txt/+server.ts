import type { RequestHandler } from '@sveltejs/kit';

// Served from a route rather than static/ so the sitemap line can carry the
// real origin (ORIGIN in production). /play and /api need a session and have
// nothing to index.
export const GET: RequestHandler = ({ url }) =>
	new Response(
		['User-agent: *', 'Disallow: /api', 'Disallow: /play', 'Allow: /', '', `Sitemap: ${url.origin}/sitemap.xml`, ''].join('\n'),
		{ headers: { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'public, max-age=3600' } }
	);
