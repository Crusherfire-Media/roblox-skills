#!/usr/bin/env node
// Builds the eval sandbox: a minimal Rojo + pesde game on a Baseplate, with Vide
// installed, Roblox type definitions, and a sourcemap, committed to a fresh git repo
// so the runner can diff each trial against it. Trials copy this folder.
//
//   node evals/harness/build-sandbox.mjs <dest> [--defs <globalTypes.d.luau>] [--force]
//
// Needs network for `pesde install` and the type definitions (unless --defs is given),
// and the Rokit tools from the sandbox's rokit.toml.

import { spawnSync } from "node:child_process";
import { copyFileSync, cpSync, existsSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseArgs } from "./lib/args.mjs";
import { ancestorMemoryFiles, isInside } from "./lib/workspace.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE = path.join(HERE, "sandbox-template");
const REPO_ROOT = path.resolve(HERE, "..", "..");
export const DEFINITIONS_URL = "https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau";

function step(label, cmd, args, cwd) {
	process.stdout.write(`- ${label}\n`);
	const res = spawnSync(cmd, args, { cwd, encoding: "utf8", windowsHide: true, maxBuffer: 64 * 1024 * 1024 });
	if (res.error || res.status !== 0) {
		const output = `${res.stdout ?? ""}${res.stderr ?? ""}`.trim();
		throw new Error(`${label} failed (${res.error?.message ?? `exit ${res.status}`}):\n${output.slice(-3000)}`);
	}
	return res;
}

async function downloadDefinitions(file) {
	process.stdout.write(`- download Roblox type definitions\n`);
	const res = await fetch(DEFINITIONS_URL, { headers: { "User-Agent": "roblox-skills-evals/1.0" }, redirect: "follow" });
	if (!res.ok) throw new Error(`definitions download failed: HTTP ${res.status}`);
	const text = await res.text();
	if (!text.includes("declare function warn")) throw new Error("definitions download returned an unexpected file");
	writeFileSync(file, text);
}

async function main() {
	const { flags, positional } = parseArgs(process.argv.slice(2), { booleans: ["force"] });
	if (positional.length !== 1) {
		console.error("usage: node evals/harness/build-sandbox.mjs <dest> [--defs <file>] [--force]");
		process.exit(2);
	}
	const dest = path.resolve(positional[0]);
	if (isInside(REPO_ROOT, dest)) throw new Error("build the sandbox outside the repository");
	const memory = ancestorMemoryFiles(path.dirname(dest));
	if (memory.length > 0) {
		throw new Error(`a CLAUDE.md above ${dest} would load into every trial: ${memory.join(", ")}`);
	}
	if (existsSync(dest) && readdirSync(dest).length > 0) {
		if (!flags.force) throw new Error(`${dest} is not empty (pass --force to replace it)`);
		rmSync(dest, { recursive: true, force: true });
	}

	process.stdout.write(`Building sandbox in ${dest}\n`);
	cpSync(TEMPLATE, dest, { recursive: true });
	step("pesde install", "pesde", ["install"], dest);

	const defs = path.join(dest, "globalTypes.d.luau");
	if (flags.defs) copyFileSync(path.resolve(flags.defs), defs);
	else await downloadDefinitions(defs);

	step("rojo sourcemap", "rojo", ["sourcemap", "default.project.json", "-o", "sourcemap.json", "--include-non-scripts"], dest);
	step(
		"luau-lsp analyze src",
		"luau-lsp",
		["analyze", "--platform=roblox", "--definitions:@roblox=globalTypes.d.luau", "--sourcemap=sourcemap.json", "--ignore=**/roblox_packages/**", "src"],
		dest,
	);
	step("selene src", "selene", ["src"], dest);
	step("stylua --check src", "stylua", ["--check", "src"], dest);

	step("git init", "git", ["init", "-q", "-b", "main"], dest);
	step("git add", "git", ["add", "-A"], dest);
	step(
		"git commit",
		"git",
		["-c", "user.name=eval-harness", "-c", "user.email=eval-harness@localhost", "commit", "-q", "-m", "Sandbox starting point"],
		dest,
	);
	const head = step("git rev-parse", "git", ["rev-parse", "HEAD"], dest).stdout.trim();
	process.stdout.write(`Sandbox ready at ${dest} (commit ${head.slice(0, 12)})\n`);
}

main().catch((err) => {
	console.error(`build-sandbox: ${err.message}`);
	process.exit(1);
});
