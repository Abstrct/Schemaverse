// Client-side game state: who I am, where the clock is, and the live feed of
// NOTIFY messages from the server-sent events stream.
import { browser } from '$app/environment';

export type Me = {
	id: number; username: string; balance: number; fuel_reserve: number; symbol: string | null; rgb: string | null;
	tic: number; round: number; ships: number; planets: number; active_fleets: number;
};
export type Notice = { channel: string; payload: string; at: number; kind: 'tic' | 'notice' };

class Game {
	me = $state<Me | null>(null);
	tic = $state(0);
	notices = $state<Notice[]>([]);
	connected = $state(false);
	private es: EventSource | null = null;
	private ticListeners = new Set<(tic: number) => void>();

	async refresh() {
		const r = await fetch('/api/me');
		if (r.status === 401) {
			this.me = null;
			return false;
		}
		const me = (await r.json()) as Me;
		this.me = me;
		this.tic = Number(me.tic);
		return true;
	}

	connect() {
		if (!browser || this.es) return;
		this.es = new EventSource('/api/events');
		this.es.addEventListener('hello', () => (this.connected = true));
		this.es.addEventListener('tic', (e) => {
			const n = JSON.parse((e as MessageEvent).data);
			this.tic = Number(n.payload);
			void this.refresh();
			for (const l of this.ticListeners) l(this.tic);
		});
		this.es.addEventListener('notice', (e) => {
			const n = JSON.parse((e as MessageEvent).data);
			this.push({ ...n, kind: 'notice' });
		});
		this.es.onerror = () => (this.connected = false);
	}

	disconnect() {
		this.es?.close();
		this.es = null;
		this.connected = false;
	}

	onTic(l: (tic: number) => void) {
		this.ticListeners.add(l);
		return () => this.ticListeners.delete(l);
	}

	push(n: Notice) {
		this.notices = [n, ...this.notices].slice(0, 200);
	}

	async logout() {
		await fetch('/api/auth/logout', { method: 'POST' });
		this.disconnect();
		this.me = null;
	}
}

export const game = new Game();

/** Run SQL as the player. Returns the raw API response body. */
export async function runSql(sql: string) {
	const r = await fetch('/api/sql', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ sql }) });
	return r.json();
}
