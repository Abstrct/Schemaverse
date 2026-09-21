// Shapes returned by map_snapshot() and friends.
export type Badge = { id: number; username: string; symbol: string | null; rgb: string | null };
export type Planet = { id: number; name: string; x: number; y: number; mine_limit: number; conqueror_id: number | null; conqueror: Badge | null };
export type Ship = {
	id: number; name: string; fleet_id: number | null; x: number; y: number; direction: number; speed: number;
	target_speed: number | null; target_direction: number | null; destination_x: number | null; destination_y: number | null;
	current_health: number; max_health: number; current_fuel: number; max_fuel: number; max_speed: number; range: number;
	attack: number; defense: number; engineering: number; prospecting: number; action: string | null; action_target_id: number | null; last_action_tic: number | null;
};
export type Contact = { id: number; name: string; player_id: number; x: number; y: number; health: string; player: Badge };
export type Snap = {
	tic: number; round: number;
	bounds: { min_x: number; max_x: number; min_y: number; max_y: number };
	me: { id: number; username: string; symbol: string | null; rgb: string | null; balance: number; fuel_reserve: number };
	planets: Planet[]; ships: Ship[]; contacts: Contact[];
};

/** Player colours stay inside the pin palette: you are steel, everyone else a cool grey or blue. */
export const ME_COLOR = '#7d96cc';
const OTHERS = ['#e3e5ec', '#4b62b3', '#a9b8dc', '#6b7fb0', '#cdd3e2', '#8fa0cf'];
export function playerColor(id: number, meId: number) {
	if (id === meId) return ME_COLOR;
	return OTHERS[Math.abs(id * 2654435761) % OTHERS.length];
}

/** What a ship is doing, as a colour on its cockpit and engine stripes. Cool tones only, plus the danger red for attack. */
export const ACTION_COLORS: Record<string, string> = {
	idle: ME_COLOR,      // steel: nothing queued
	moving: '#8fb0ff',   // glow: a course is set
	MINE: '#7fd6e0',     // ice: mining
	ATTACK: '#e06a5e',   // danger: attacking
	REPAIR: '#8fd7a8'    // mint: repairing
};
export function actionColor(action: string | null, hasCourse: boolean) {
	if (action && ACTION_COLORS[action]) return ACTION_COLORS[action];
	return hasCourse ? ACTION_COLORS.moving : ACTION_COLORS.idle;
}
