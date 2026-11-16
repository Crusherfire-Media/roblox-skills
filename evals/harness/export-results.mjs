#!/usr/bin/env node
// Copies a results folder into the repo without machine-specific paths: drops the
// trial projects and judge work folders, and replaces the results folder's path and
// the home folder with placeholders in every text file.
//
//   node evals/harness/export-results.mjs --results <dir> --dest evals/<skill>/results/<date> [--transcripts]
//
// Transcripts are left out unless --transcripts is given (they run to hundreds of KB
// per trial).

import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseArgs } from "./lib/args.mjs";

const SKIP_DIRS = new Set(["project", "plugin", ".judge-work"]);
const TEXT = /\.(json|jsonl|md|diff|log|luau|lua|txt)$/i;

// Every spelling of p that can appear in a file: either drive-letter case (luau-lsp
// prints it in lower case), backslashes or forward slashes, raw or JSON-escaped.
export function variants(p) {
	const set = new Set();
	for (const drive of [p, p.replace(/^([A-Z]):/, (_, d) => `${d.toLowerCase()}:`)]) {
		for (const slashes of [drive, drive.replace(/\\/g, "/")]) {
			set.add(slashes);
			set.add(JSON.stringify(slashes).slice(1, -1));
		}
	}
	return [...set].sort((a, b) => b.length - a.length);
}

export function redact(text, resultsDir, home = os.homedir()) {
	let out = text;
	for (const v of variants(path.resolve(resultsDir))) out = out.split(v).join("<results>");
	for (const v of variants(home)) out = out.split(v).join("~");
	return out;
}

function copyTree(src, dest, opts) {
	mkdirSync(dest, { recursive: true });
	for (const entry of readdirSync(src, { withFileTypes: true })) {
		const from = path.join(src, entry.name);
		const to = path.join(dest, entry.name);
		if (entry.isDirectory()) {
			if (SKIP_DIRS.has(entry.name)) continue;
			copyTree(from, to, opts);
			continue;
		}
		if (entry.name === "transcript.jsonl" && !opts.transcripts) continue;
		if (entry.name === "stderr.log" && statSync(from).size === 0) continue;
		if (TEXT.test(entry.name)) writeFileSync(to, redact(readFileSync(from, "utf8"), opts.results));
		else copyFileSync(from, to);
	}
}

function main() {
	const { flags } = parseArgs(process.argv.slice(2), { booleans: ["transcripts"] });
	if (!flags.results || !flags.dest) {
		console.error("usage: node evals/harness/export-results.mjs --results <dir> --dest <dir> [--transcripts]");
		process.exit(2);
	}
	const results = path.resolve(flags.results);
	const dest = path.resolve(flags.dest);
	if (!existsSync(path.join(results, "benchmark.json"))) throw new Error(`run aggregate.mjs on ${results} first`);
	if (existsSync(dest) && readdirSync(dest).length > 0) throw new Error(`${dest} is not empty`);
	copyTree(results, dest, { results, transcripts: !!flags.transcripts });
	process.stdout.write(`Exported ${results} to ${dest}\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	try {
		main();
	} catch (err) {
		console.error(`export-results: ${err.message}`);
		process.exit(1);
	}
}
