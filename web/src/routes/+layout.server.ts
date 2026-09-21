import type { LayoutServerLoad } from './$types';

// Whether a player is logged in, for the public pages' "fork this" and
// "your profile" affordances. Nothing else about the session leaves the server.
export const load: LayoutServerLoad = ({ locals }) => ({
	me: locals.session ? { username: locals.session.username } : null
});
