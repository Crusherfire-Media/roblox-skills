#!/usr/bin/env node
// Copies a results folder into the repo without machine-specific paths, replacing the
// results folder's path and the home folder with placeholders in every text file.
//
//   node evals/harness/export-results.mjs --results <dir> --dest evals/<skill>/results/<date> [--full] [--transcripts]
//
// By default it copies only what a reader needs to check a verdict: the summaries, the
// judge's verdicts, the grading, each trial's final message, and its diff. The repo is
// cloned by everyone who installs the plugin, so judge prompts (which repeat the diffs),
// copies of output files, and metrics stay out. --full copies everything except the
// trial projects; transcripts also need --transcripts (they run to hundreds of KB each).

import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseArgs } from "./lib/args.mjs";

const SKIP_DIRS = new Set(["project", "plugin", ".judge-work"]);
const TEXT = /\.(json|jsonl|md|diff|log|luau|lua|txt)$/i;
const KEEP = new Set([
	"benchmark.json",
	"benchmark.md",
	"judge-summary.json",
	"triggers.json",
	"comparison.json",
	"mapping.json",
	"grading.json",
	"final-message.md",
	"changes.diff",
]);

export function keepFile(name, size, opts = {}) {
	if (name === "transcript.jsonl") return !!opts.transcripts;
	if (!opts.full) return KEEP.has(name);
	return !(name === "stderr.log" && size === 0);
}

// Every spelling of p that can appear in a file: either drive-letter case (luau-lsp
// prints it in lower case), backslashes or forward slashes, raw or JSON-escaped once or
// twice (a tool's error output stored as a string inside a JSON string).
export function variants(p) {
	const set = new Set();
	const escape = (s) => JSON.stringify(s).slice(1, -1);
	for (const drive of [p, p.replace(/^([A-Z]):/, (_, d) => `${d.toLowerCase()}:`)]) {
		for (const slashes of [drive, drive.replace(/\\/g, "/")]) {
			set.add(slashes);
			set.add(escape(slashes));
			set.add(escape(escape(slashes)));
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
	for (const entry of readdirSync(src, { withFileTypes: true })) {
		const from = path.join(src, entry.name);
		const to = path.join(dest, entry.name);
		if (entry.isDirectory()) {
			if (SKIP_DIRS.has(entry.name)) continue;
			copyTree(from, to, opts);
			continue;
		}
		if (!keepFile(entry.name, statSync(from).size, opts)) continue;
		mkdirSync(dest, { recursive: true });
		if (TEXT.test(entry.name)) writeFileSync(to, redact(readFileSync(from, "utf8"), opts.results));
		else copyFileSync(from, to);
	}
}

function main() {
	const { flags } = parseArgs(process.argv.slice(2), { booleans: ["full", "transcripts"] });
	if (!flags.results || !flags.dest) {
		console.error("usage: node evals/harness/export-results.mjs --results <dir> --dest <dir> [--full] [--transcripts]");
		process.exit(2);
	}
	const results = path.resolve(flags.results);
	const dest = path.resolve(flags.dest);
	if (!existsSync(path.join(results, "benchmark.json"))) throw new Error(`run aggregate.mjs on ${results} first`);
	if (existsSync(dest) && readdirSync(dest).length > 0) throw new Error(`${dest} is not empty`);
	copyTree(results, dest, { results, full: !!flags.full, transcripts: !!flags.transcripts });
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
