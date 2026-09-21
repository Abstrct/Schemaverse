// Server-sent events: every NOTIFY the player's connection receives (the tic
// channel and the player's private error channel), as it arrives.
import type { RequestHandler } from './$types';
import type { Listener } from '$lib/server/sessions';

export const GET: RequestHandler = ({ locals }) => {
	const s = locals.session!;
	const encoder = new TextEncoder();
	let listener: Listener | undefined;
	let heartbeat: ReturnType<typeof setInterval> | undefined;
	const stream = new ReadableStream({
		start(controller) {
			const send = (event: string, data: unknown) =>
				controller.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));
			send('hello', { username: s.username, errorChannel: s.errorChannel });
			listener = (n) => send(n.channel === 'tic' ? 'tic' : 'notice', n);
			s.listeners.add(listener);
			heartbeat = setInterval(() => controller.enqueue(encoder.encode(': ping\n\n')), 25_000);
		},
		cancel() {
			if (listener) s.listeners.delete(listener);
			if (heartbeat) clearInterval(heartbeat);
		}
	});
	return new Response(stream, {
		headers: {
			'content-type': 'text/event-stream',
			'cache-control': 'no-cache',
			connection: 'keep-alive',
			'x-accel-buffering': 'no'
		}
	});
};
