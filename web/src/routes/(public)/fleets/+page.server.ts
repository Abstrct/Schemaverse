import type { PageServerLoad } from './$types';
import { listFleets } from '$lib/server/public';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ setHeaders }) => {
	const { fleets, clock } = await listFleets();
	setHeaders({ 'cache-control': 'public, max-age=30' });
	return {
		fleets, clock,
		seo: {
			title: `Shared fleet scripts · ${SITE_NAME}`,
			description: `${fleets.length} PL/pgSQL fleet scripts that Schemaverse players have published. Read them, fork them into your own fleets, and let PostgreSQL fly your ships.`,
			jsonld: {
				'@context': 'https://schema.org', '@type': 'ItemList', name: 'Shared Schemaverse fleet scripts',
				itemListElement: fleets.slice(0, 50).map((f, i) => ({ '@type': 'ListItem', position: i + 1, name: f.name || `fleet ${f.id}`, url: `/fleet/${f.id}` }))
			}
		}
	};
};
