<script lang="ts">
	import { page } from '$app/state';
	const words = $derived(page.status === 404 ? ['NOT', 'Found'] : page.status === 503 ? ['NOT', 'Open'] : ['SQL', 'Error']);
</script>

<svelte:head><title>{page.status} · Schemaverse</title><meta name="robots" content="noindex" /></svelte:head>

<div class="err">
	<a href="/"><img src="/brand/wordmark-light.svg" alt="Schemaverse" width="106" height="30" /></a>
	<div class="lockup"><span class="short">{words[0]}</span><span class="long">{words[1]}</span></div>
	<p class="mono">{page.status} · {page.error?.message ?? 'something went wrong'}</p>
	<p class="muted">Try the <a href="/players">standings</a>, the <a href="/fleets">shared scripts</a>, the <a href="/replays">replays</a>, or <a href="/">go home</a>.</p>
</div>

<style>
	.err { min-height: 100vh; display: flex; flex-direction: column; justify-content: center; gap: 18px; max-width: 720px; margin: 0 auto; padding: 40px 24px; }
	.lockup .long { font-size: 96px; }
	p { margin: 0; }
	.muted a { text-decoration: underline; text-underline-offset: 3px; }
</style>
