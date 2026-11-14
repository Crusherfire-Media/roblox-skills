import os from "node:os";
import path from "node:path";
import { existsSync, readFileSync } from "node:fs";

// Minimal --flag value parser for the harness CLIs. Flags listed in `booleans`
// take no value; every other flag needs one.
export function parseArgs(argv, { booleans = [] } = {}) {
	const flags = {};
	const positional = [];
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (!arg.startsWith("--")) {
			positional.push(arg);
			continue;
		}
		const eq = arg.indexOf("=");
		const name = eq === -1 ? arg.slice(2) : arg.slice(2, eq);
		if (booleans.includes(name)) {
			flags[name] = true;
		} else if (eq !== -1) {
			flags[name] = arg.slice(eq + 1);
		} else {
			if (i + 1 >= argv.length) throw new Error(`--${name} needs a value`);
			flags[name] = argv[++i];
		}
	}
	return { flags, positional };
}

export function intFlag(value, name, { min = 1, max = 1000, fallback }) {
	if (value === undefined) return fallback;
	const n = Number(value);
	if (!Number.isInteger(n) || n < min || n > max) throw new Error(`--${name} must be an integer from ${min} to ${max}`);
	return n;
}

export function listFlag(value) {
	if (!value) return [];
	return String(value)
		.split(",")
		.map((s) => s.trim())
		.filter(Boolean);
}

// The installed skill-creator plugin, from Claude Code's plugin registry. Set
// SKILL_CREATOR_DIR to the folder that holds scripts/ to use another copy.
export function skillCreatorDir() {
	if (process.env.SKILL_CREATOR_DIR) return path.resolve(process.env.SKILL_CREATOR_DIR);
	const registry = path.join(process.env.CLAUDE_CONFIG_DIR ?? path.join(os.homedir(), ".claude"), "plugins", "installed_plugins.json");
	if (existsSync(registry)) {
		const data = JSON.parse(readFileSync(registry, "utf8"));
		for (const [key, installs] of Object.entries(data.plugins ?? {})) {
			if (!key.startsWith("skill-creator@")) continue;
			for (const install of installs) {
				const dir = path.join(install.installPath, "skills", "skill-creator");
				if (existsSync(path.join(dir, "scripts", "aggregate_benchmark.py"))) return dir;
			}
		}
	}
	throw new Error("skill-creator plugin not found; install it or set SKILL_CREATOR_DIR");
}
