import type { PageServerLoad } from './$types';
import { listRounds } from '$lib/server/public';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ setHeaders }) => {
	const { rounds, clock } = await listRounds();
	setHeaders({ 'cache-control': 'public, max-age=60' });
	return {
		rounds, clock,
		seo: {
			title: `Round replays · ${SITE_NAME}`,
			description: `Every round of Schemaverse, the space strategy game played in PostgreSQL: who fought, who conquered, who lost ships, and which trophies were awarded. Round ${clock.round} is in progress.`,
			jsonld: {
				'@context': 'https://schema.org', '@type': 'ItemList', name: 'Schemaverse rounds',
				itemListElement: rounds.slice(0, 50).map((r, i) => ({ '@type': 'ListItem', position: i + 1, name: `Round ${r.round_id}`, url: `/replay/${r.round_id}` }))
			}
		}
	};
};
