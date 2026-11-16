import { readFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";

export const SETUPS = ["with-skill", "baseline"];

// skill-creator's aggregate_benchmark.py reads these folder names, and sorts
// "with_skill" before "without_skill" so its delta is with-skill minus baseline.
export const CONFIG_DIR = { "with-skill": "with_skill", baseline: "without_skill" };

export function readPluginName(pluginDir) {
	const manifest = path.join(pluginDir, ".claude-plugin", "plugin.json");
	let parsed;
	try {
		parsed = JSON.parse(readFileSync(manifest, "utf8"));
	} catch (err) {
		throw new Error(`cannot read plugin manifest ${manifest}: ${err.message}`);
	}
	if (typeof parsed.name !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(parsed.name)) {
		throw new Error(`plugin manifest ${manifest} has no valid "name"`);
	}
	return parsed.name;
}

// Flags that keep a session free of everything configured on this machine.
// - --setting-sources project,local drops user settings: user-scope enabledPlugins
//   (a private plugin with the same skills would contaminate a trial), user hooks,
//   user permissions, and user skills.
// - --strict-mcp-config drops user and claude.ai MCP servers.
// - claudeMdExcludes drops ~/.claude/CLAUDE.md and ~/.claude/rules, which load even
//   without user settings.
// - --restricted confines Read, Grep, Glob, Edit, Write, Bash, and PowerShell to the
//   working folder, so a trial can't search the disk and find a private plugin's
//   SKILL.md files or another trial's output. It also ignores the project's own
//   .claude/settings.json; the project's CLAUDE.md still loads.
export function isolationArgs({ pluginDir = null, extraDisabledPlugins = [] } = {}) {
	const home = os.homedir().replace(/\\/g, "/");
	const settings = { claudeMdExcludes: [`${home}/.claude/**`] };
	if (extraDisabledPlugins.length > 0) {
		settings.enabledPlugins = Object.fromEntries(extraDisabledPlugins.map((p) => [p, false]));
	}
	const args = ["--restricted", "--setting-sources", "project,local", "--strict-mcp-config", "--settings", JSON.stringify(settings)];
	// --add-dir lets the file tools read the plugin's references/ files, which
	// --restricted would otherwise block. Pass a throwaway copy of the plugin, since
	// acceptEdits also lets the session edit files there.
	if (pluginDir) args.push("--plugin-dir", pluginDir, "--add-dir", pluginDir);
	return args;
}

const isBuiltin = (plugin) => String(plugin.source ?? "").endsWith("@builtin");

// Checks the init event (and the hook events) of one session against its setup.
// with-skill: the plugin under test is the only non-built-in plugin, and every
// namespaced skill comes from it. baseline: no non-built-in plugin and no namespaced
// skill. Both: no MCP servers, and nothing else whose name mentions Roblox.
export function checkIsolation(initSummary, { setup, expectedPlugin = null, hooks = [] }) {
	const problems = [];
	if (!initSummary) {
		return { ok: false, problems: ["no init event in the transcript"] };
	}
	if (setup === "with-skill" && !expectedPlugin) {
		throw new Error("with-skill isolation check needs the expected plugin name");
	}
	const own = (name) => setup === "with-skill" && (name === expectedPlugin || name.startsWith(`${expectedPlugin}:`));

	const extraPlugins = initSummary.plugins.filter((p) => !isBuiltin(p));
	if (setup === "with-skill") {
		const target = extraPlugins.filter((p) => p.name === expectedPlugin && p.source === `${expectedPlugin}@inline`);
		if (target.length !== 1) problems.push(`plugin under test "${expectedPlugin}" is not loaded from --plugin-dir`);
		for (const p of extraPlugins) {
			if (!(p.name === expectedPlugin && p.source === `${expectedPlugin}@inline`)) {
				problems.push(`unexpected plugin ${p.source ?? p.name}`);
			}
		}
	} else {
		for (const p of extraPlugins) problems.push(`unexpected plugin ${p.source ?? p.name}`);
	}

	for (const skill of initSummary.skills) {
		if (skill.includes(":") && !own(skill)) problems.push(`unexpected namespaced skill ${skill}`);
		else if (/roblox/i.test(skill) && !own(skill)) problems.push(`unexpected Roblox skill ${skill}`);
	}
	for (const agent of initSummary.agents) {
		if (/roblox/i.test(agent) && !own(agent)) problems.push(`unexpected Roblox agent ${agent}`);
	}
	for (const server of initSummary.mcp_servers) {
		problems.push(`unexpected MCP server ${server.name}`);
	}
	if (setup === "baseline" && hooks.length > 0) {
		const names = [...new Set(hooks.map((h) => h.hook_name))].join(", ");
		problems.push(`hooks ran in the baseline: ${names}`);
	}
	return { ok: problems.length === 0, problems };
}
