// Small formatters shared by the public pages.
export const k = (n: number | string | null | undefined) => {
	const v = Number(n ?? 0);
	return v >= 1e6 ? (v / 1e6).toFixed(2) + 'M' : v >= 1e4 ? Math.round(v / 1e3) + 'k' : Math.round(v).toLocaleString();
};
export const n = (v: number | string | null | undefined) => Math.round(Number(v ?? 0)).toLocaleString();
export const day = (iso: string) => new Date(iso).toLocaleDateString('en-CA');
export const ago = (iso: string) => {
	const s = (Date.now() - new Date(iso).getTime()) / 1000;
	if (s < 3600) return `${Math.max(1, Math.floor(s / 60))} min ago`;
	if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
	return `${Math.floor(s / 86400)} d ago`;
};
