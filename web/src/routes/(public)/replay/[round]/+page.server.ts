import type { PageServerLoad } from './$types';
import { getRound } from '$lib/server/public';
import { roundCard, pinSvg } from '$lib/server/og/cards';
import { SITE_NAME } from '$lib/seo';

export const load: PageServerLoad = async ({ params, url, setHeaders }) => {
	const round = await getRound(Number(params.round));
	const card = pinSvg(roundCard(round));
	setHeaders({ 'cache-control': 'public, max-age=60' });
	const t = Number(url.searchParams.get('tic'));
	const tic = Number.isFinite(t) && t > 0 ? Math.min(t, round.last_tic) : round.last_tic;
	const winners = round.trophies.slice(0, 3).map((t) => `${t.username} (${t.name})`).join(', ');
	const description = round.current
		? `Round ${round.round} of Schemaverse is in progress at tic ${round.clock.tic}: ${round.players} players, ${round.attacks} attacks, ${round.conquests} conquests, ${round.explosions} ships lost so far.`
		: `Round ${round.round} of Schemaverse: ${round.players} players over ${round.last_tic} tics, ${round.attacks} attacks, ${round.conquests} conquests, ${round.explosions} ships lost.${winners ? ' Trophies: ' + winners + '.' : ''}`;
	return {
		round, card, tic,
		seo: {
			title: `Round ${round.round}${tic !== round.last_tic ? ` at tic ${tic}` : ''} · replay · ${SITE_NAME}`,
			description,
			image: `/og/replay/${round.round}.png`,
			type: 'article',
			jsonld: {
				'@context': 'https://schema.org', '@type': 'Event', name: `Schemaverse round ${round.round}`, description,
				eventStatus: round.current ? 'https://schema.org/EventScheduled' : 'https://schema.org/EventCompleted',
				eventAttendanceMode: 'https://schema.org/OnlineEventAttendanceMode',
				location: { '@type': 'VirtualLocation', url: '/' },
				organizer: { '@type': 'Organization', name: SITE_NAME }
			}
		}
	};
};
