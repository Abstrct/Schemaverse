<script lang="ts">
	// Crawler and link-preview metadata for whatever page is open. A page's
	// load function can return `seo` to describe itself; without it the front
	// door's defaults apply. Everything under /play needs a session and only
	// ever renders "Opening a connection as you…" to a crawler, so it is marked
	// noindex here and again in an X-Robots-Tag header from hooks.
	import { page } from '$app/state';
	import { SITE_NAME, TAGLINE, DESCRIPTION, REPO, OG_IMAGE, OG_IMAGE_SIZE, type Seo } from '$lib/seo';

	const origin = $derived(page.url.origin);
	const canonical = $derived(origin + (page.url.pathname.replace(/\/+$/, '') || '/'));
	const gated = $derived(page.url.pathname.startsWith('/play') || page.url.pathname.startsWith('/api'));
	const seo = $derived((page.data as { seo?: Seo }).seo);
	const title = $derived(seo ? seo.title : `${SITE_NAME} · ${TAGLINE}`);
	const description = $derived(seo?.description ?? DESCRIPTION);
	const image = $derived(new URL(seo?.image ?? OG_IMAGE, origin).href);
	const type = $derived(seo?.type ?? 'website');

	const ld = $derived(
		JSON.stringify(
			seo?.jsonld ?? {
				'@context': 'https://schema.org',
				'@type': 'VideoGame',
				name: SITE_NAME,
				alternateName: `${SITE_NAME}: ${TAGLINE}`,
				url: origin + '/',
				description,
				image,
				genre: ['Strategy', 'Programming game'],
				gamePlatform: ['Web browser', 'PostgreSQL'],
				applicationCategory: 'Game',
				operatingSystem: 'Any',
				playMode: 'MultiPlayer',
				isAccessibleForFree: true,
				offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
				sameAs: [REPO]
			}
		).replace(/</g, '\\u003c')
	);
</script>

<svelte:head>
	{#if gated}
		<meta name="robots" content="noindex, nofollow" />
	{:else}
		{#if seo}<title>{title}</title>{/if}
		<meta name="description" content={description} />
		<link rel="canonical" href={canonical} />
		<meta property="og:type" content={type} />
		<meta property="og:site_name" content={SITE_NAME} />
		<meta property="og:title" content={title} />
		<meta property="og:description" content={description} />
		<meta property="og:url" content={canonical} />
		<meta property="og:image" content={image} />
		<meta property="og:image:width" content={String(OG_IMAGE_SIZE.width)} />
		<meta property="og:image:height" content={String(OG_IMAGE_SIZE.height)} />
		<meta property="og:image:alt" content={title} />
		<meta property="og:locale" content="en_US" />
		<meta name="twitter:card" content="summary_large_image" />
		<meta name="twitter:title" content={title} />
		<meta name="twitter:description" content={description} />
		<meta name="twitter:image" content={image} />
		{@html `<script type="application/ld+json">${ld}</script>`}
	{/if}
</svelte:head>
