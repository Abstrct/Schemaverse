<script lang="ts">
	import '../app.css';
	import Seo from '$lib/components/Seo.svelte';
	let { children } = $props();
</script>

<Seo />

{@render children()}
