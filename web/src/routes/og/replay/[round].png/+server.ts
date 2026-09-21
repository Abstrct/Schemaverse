import type { RequestHandler } from './$types';
import { getRound } from '$lib/server/public';
import { roundCard, pinSvg } from '$lib/server/og/cards';
import { renderPng, PNG_HEADERS } from '$lib/server/og/render';

export const GET: RequestHandler = async ({ params }) =>
	new Response(renderPng(pinSvg(roundCard(await getRound(Number(params.round))))), { headers: PNG_HEADERS });
