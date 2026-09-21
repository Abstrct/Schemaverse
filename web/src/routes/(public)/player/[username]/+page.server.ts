import type { PageServerLoad } from './$types';
import { getProfile } from '$lib/server/public';
import { playerCard, pinSvg } from '$lib/server/og/cards';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ params, setHeaders }) => {
	const profile = await getProfile(params.username);
	const card = pinSvg(playerCard(profile));
	setHeaders({ 'cache-control': 'public, max-age=30' });
	const u = profile.player.username;
	const description = `${u} on Schemaverse: ${profile.trophies.length} trophies (${profile.trophy_score} points), ${profile.planets.length} planets held in round ${profile.clock.round}, ${profile.fleets.length} shared fleet scripts. Playing since ${profile.player.created.slice(0, 10)}.`;
	return {
		profile, card,
		seo: {
			title: `${u} · trophy case · ${SITE_NAME}`,
			description,
			image: `/og/player/${u}.png`,
			type: 'profile',
			jsonld: {
				'@context': 'https://schema.org', '@type': 'ProfilePage',
				dateCreated: profile.player.created,
				mainEntity: { '@type': 'Person', name: u, identifier: String(profile.player.id), description,
					award: profile.trophies.map((t) => t.name) }
			}
		}
	};
};
