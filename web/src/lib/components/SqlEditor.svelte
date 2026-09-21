<script lang="ts">
	// CodeMirror 6 with PostgreSQL syntax and schema-aware completion. Chosen
	// over Monaco: a tenth of the size, SSR-safe, and lang-sql takes a schema
	// map for completion out of the box.
	import { onMount } from 'svelte';
	import { EditorView, keymap, lineNumbers, highlightActiveLine, highlightActiveLineGutter } from '@codemirror/view';
	import { EditorState, Compartment } from '@codemirror/state';
	import { defaultKeymap, history, historyKeymap, indentWithTab } from '@codemirror/commands';
	import { sql, PostgreSQL } from '@codemirror/lang-sql';
	import { autocompletion, closeBrackets } from '@codemirror/autocomplete';
	import { syntaxHighlighting, defaultHighlightStyle, bracketMatching } from '@codemirror/language';

	let {
		value = $bindable(''),
		schema = {} as Record<string, string[]>,
		onrun,
		minHeight = '140px',
		placeholder = ''
	}: { value?: string; schema?: Record<string, string[]>; onrun?: (text: string) => void; minHeight?: string; placeholder?: string } = $props();

	let host: HTMLDivElement;
	let view: EditorView;
	const langConf = new Compartment();

	function langExt() {
		return sql({ dialect: PostgreSQL, schema, upperCaseKeywords: true });
	}

	onMount(() => {
		view = new EditorView({
			parent: host,
			state: EditorState.create({
				doc: value,
				extensions: [
					lineNumbers(), highlightActiveLine(), highlightActiveLineGutter(), history(), closeBrackets(), bracketMatching(),
					syntaxHighlighting(defaultHighlightStyle), autocompletion(),
					langConf.of(langExt()),
					keymap.of([
						{ key: 'Mod-Enter', run: () => { onrun?.(selectedOrAll()); return true; } },
						indentWithTab, ...defaultKeymap, ...historyKeymap
					]),
					EditorView.updateListener.of((u) => { if (u.docChanged) value = u.state.doc.toString(); }),
					EditorView.theme({ '&': { minHeight }, '.cm-scroller': { minHeight } })
				]
			})
		});
		return () => view.destroy();
	});

	$effect(() => {
		// schema arrives after mount
		schema;
		if (view) view.dispatch({ effects: langConf.reconfigure(langExt()) });
	});
	$effect(() => {
		if (view && value !== view.state.doc.toString()) {
			view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: value } });
		}
	});

	export function selectedOrAll() {
		const sel = view.state.selection.main;
		return sel.empty ? view.state.doc.toString() : view.state.sliceDoc(sel.from, sel.to);
	}
	export function focus() { view?.focus(); }
</script>

<div bind:this={host} class="host" data-placeholder={placeholder}></div>

<style>
	.host :global(.cm-editor) { height: 100%; }
</style>
