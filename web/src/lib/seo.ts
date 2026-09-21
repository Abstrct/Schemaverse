// What the site says about itself to crawlers and link previews. One place,
// so the title, the social card and the structured data never drift apart.
export const SITE_NAME = 'Schemaverse';
export const TAGLINE = 'A space war played in SQL';
export const DESCRIPTION =
	'A space strategy game played entirely inside PostgreSQL. Buy ships with INSERT, steer them in SQL, and write PL/pgSQL scripts that fly your fleet. Free, in the browser or psql.';
export const REPO = 'https://github.com/Abstrct/Schemaverse';
export const OG_IMAGE = '/og.png';
export const OG_IMAGE_SIZE = { width: 1200, height: 630 };

/** Per-page metadata, returned from a load function as `seo`. Paths are made absolute by the Seo component. */
export type Seo = {
	title: string;
	description: string;
	/** Path or URL of a 1200x630 image. Defaults to the site card. */
	image?: string;
	/** og:type. Defaults to website. */
	type?: string;
	/** A schema.org object, serialised as JSON-LD. */
	jsonld?: Record<string, unknown>;
};
