import type { PageServerLoad } from './$types';
import { listPlayers } from '$lib/server/public';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ setHeaders }) => {
	const { players, clock } = await listPlayers();
	setHeaders({ 'cache-control': 'public, max-age=30' });
	return {
		players, clock,
		seo: {
			title: `Standings · Round ${clock.round} · ${SITE_NAME}`,
			description: `${players.length} players in round ${clock.round} of Schemaverse, the space strategy game played in PostgreSQL: planets held, trophies won, damage done. Every profile is a public trophy case.`,
			jsonld: {
				'@context': 'https://schema.org', '@type': 'ItemList', name: `Schemaverse standings, round ${clock.round}`,
				itemListElement: players.slice(0, 50).map((p, i) => ({ '@type': 'ListItem', position: i + 1, name: p.username, url: `/player/${p.username}` }))
			}
		}
	};
};
