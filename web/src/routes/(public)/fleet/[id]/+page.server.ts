import type { PageServerLoad } from './$types';
import { getFleet } from '$lib/server/public';
import { fleetCard, pinSvg } from '$lib/server/og/cards';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ params, setHeaders }) => {
	const fleet = await getFleet(Number(params.id));
	const card = pinSvg(fleetCard(fleet));
	setHeaders({ 'cache-control': 'public, max-age=30' });
	const name = fleet.name || `fleet ${fleet.id}`;
	const description = `"${name}", a ${fleet.lines}-line PL/pgSQL fleet script shared by ${fleet.username} on Schemaverse. ${fleet.script.split('\n').find((l) => l.trim() && !l.trim().startsWith('--'))?.trim().slice(0, 100) ?? ''}`;
	return {
		fleet, card,
		seo: {
			title: `${name} by ${fleet.username} · fleet script · ${SITE_NAME}`,
			description,
			image: `/og/fleet/${fleet.id}.png`,
			type: 'article',
			jsonld: {
				'@context': 'https://schema.org', '@type': 'SoftwareSourceCode',
				name, description, programmingLanguage: 'PL/pgSQL', runtimePlatform: 'PostgreSQL',
				author: { '@type': 'Person', name: fleet.username, url: `/player/${fleet.username}` },
				datePublished: fleet.shared_at, isPartOf: { '@type': 'VideoGame', name: SITE_NAME },
				text: fleet.script
			}
		}
	};
};
