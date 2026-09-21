import type { RequestHandler } from './$types';
import { getFleet } from '$lib/server/public';
import { fleetCard, pinSvg } from '$lib/server/og/cards';
import { renderPng, PNG_HEADERS } from '$lib/server/og/render';

export const GET: RequestHandler = async ({ params }) =>
	new Response(renderPng(pinSvg(fleetCard(await getFleet(Number(params.id))))), { headers: PNG_HEADERS });
