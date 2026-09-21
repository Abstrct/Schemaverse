// The card renderer needs font files on disk. They ship inside the server
// bundle as data URLs and are written to the temp dir once per process.
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import montserrat900 from './fonts/Montserrat-900.ttf?inline';
import montserrat700 from './fonts/Montserrat-700.ttf?inline';
import mono400 from './fonts/JetBrainsMono-400.ttf?inline';

let files: string[] | null = null;

export function fontFiles(): string[] {
	if (files) return files;
	const dir = join(tmpdir(), 'schemaverse-og-fonts');
	mkdirSync(dir, { recursive: true });
	const out: string[] = [];
	for (const [name, data] of [['Montserrat-900.ttf', montserrat900], ['Montserrat-700.ttf', montserrat700], ['JetBrainsMono-400.ttf', mono400]] as const) {
		const path = join(dir, name);
		if (!existsSync(path)) writeFileSync(path, Buffer.from(data.slice(data.indexOf(',') + 1), 'base64'));
		out.push(path);
	}
	return (files = out);
}
