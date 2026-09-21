// Screen facts the interface adapts to. `mobile` is a narrow viewport,
// `coarse` a touch pointer. Both are set once by the play layout from
// matchMedia and kept live; pages read them to change behaviour, not just
// styling (a bottom sheet instead of floating panels, bigger tap targets).
import { browser } from '$app/environment';

export const ui = $state({ mobile: false, coarse: false });

export function watchScreen() {
	if (!browser) return () => {};
	const narrow = window.matchMedia('(max-width: 720px)');
	const coarse = window.matchMedia('(pointer: coarse)');
	const apply = () => { ui.mobile = narrow.matches; ui.coarse = coarse.matches; };
	apply();
	narrow.addEventListener('change', apply);
	coarse.addEventListener('change', apply);
	return () => { narrow.removeEventListener('change', apply); coarse.removeEventListener('change', apply); };
}
