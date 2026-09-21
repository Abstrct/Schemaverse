import type { RequestHandler } from './$types';
import { getProfile } from '$lib/server/public';
import { playerCard, pinSvg } from '$lib/server/og/cards';
import { renderPng, PNG_HEADERS } from '$lib/server/og/render';

export const GET: RequestHandler = async ({ params }) =>
	new Response(renderPng(pinSvg(playerCard(await getProfile(params.username)))), { headers: PNG_HEADERS });
