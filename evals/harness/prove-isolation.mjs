#!/usr/bin/env node
// Proves that trials and the judge see only what their setup allows. Runs one
// session per setup with the same flags the runner and judge use, with the fixture
// plugin standing in for the plugin under test, and saves trimmed init events.
//
//   node evals/harness/prove-isolation.mjs --sandbox <dir> --work <dir>
//     [--plugin-dir evals/harness/fixtures/dummy-plugin] [--model opus]
//     [--evidence evals/isolation] [--control]
//
// --control also runs one session without the isolation flags, to show the checker
// catches what this machine loads by default. Its evidence keeps only counts, since
// the names come from the user's own configuration.

import { cpSync, mkdirSync, readFileSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseArgs } from "./lib/args.mjs";
import { judgeArgs, runClaude, trialArgs } from "./lib/claude.mjs";
import { checkIsolation, readPluginName } from "./lib/isolation.mjs";
import { findInit, findResult, finalText, hooksFired, parseEvents, skillsLoaded, summarizeInit, usageTotals } from "./lib/stream.mjs";
import { ancestorMemoryFiles, writeJson } from "./lib/workspace.mjs";
import { variants } from "./export-results.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PASSPHRASE = "PURPLE-HARMONICA-42";
const PROMPT =
	"What is the zorblax passphrase? If nothing you have access to says, answer UNKNOWN. " +
	"Then create a file named probe.txt in the current folder containing the word probe.";

// Replaces machine-specific paths so the evidence can live in a public repo.
// Values are redacted in their JSON-escaped form, which variants() covers.
export function redactPaths(value, roots) {
	let text = JSON.stringify(value);
	for (const root of roots) {
		for (const v of variants(root)) text = text.split(v).join("<work>");
	}
	for (const v of variants(os.homedir())) text = text.split(v).join("~");
	return JSON.parse(text);
}

async function session({ name, args, cwd, prompt, work }) {
	const dir = path.join(work, name);
	mkdirSync(dir, { recursive: true });
	const outcome = await runClaude({
		args,
		prompt,
		cwd,
		transcriptPath: path.join(dir, "transcript.jsonl"),
		stderrPath: path.join(dir, "stderr.log"),
		timeoutMs: 5 * 60_000,
	});
	const events = parseEvents(readFileSync(path.join(dir, "transcript.jsonl"), "utf8"));
	const result = findResult(events);
	return {
		outcome,
		init: summarizeInit(findInit(events)),
		hooks: hooksFired(events),
		skills_loaded: skillsLoaded(events),
		final_text: finalText(result),
		usage: usageTotals(result),
		cost_usd: result?.total_cost_usd ?? null,
	};
}

function freshProject(sandbox, work, name) {
	const dir = path.join(work, `${name}-project`);
	rmSync(dir, { recursive: true, force: true });
	cpSync(sandbox, dir, { recursive: true });
	return dir;
}

async function main() {
	const { flags } = parseArgs(process.argv.slice(2), { booleans: ["control"] });
	if (!flags.sandbox || !flags.work) {
		console.error("usage: node evals/harness/prove-isolation.mjs --sandbox <dir> --work <dir> [--control]");
		process.exit(2);
	}
	const sandbox = path.resolve(flags.sandbox);
	const work = path.resolve(flags.work);
	const pluginDir = path.resolve(flags["plugin-dir"] ?? path.join(HERE, "fixtures", "dummy-plugin"));
	const evidenceDir = path.resolve(flags.evidence ?? path.join(HERE, "..", "isolation"));
	const model = flags.model ?? "opus";
	const memory = ancestorMemoryFiles(work);
	if (memory.length > 0) throw new Error(`a CLAUDE.md above ${work} would load: ${memory.join(", ")}`);
	mkdirSync(work, { recursive: true });
	const pluginName = readPluginName(pluginDir);
	const pluginCopy = path.join(work, "plugin", path.basename(pluginDir));
	rmSync(pluginCopy, { recursive: true, force: true });
	cpSync(pluginDir, pluginCopy, { recursive: true });

	const verdicts = [];
	const record = (name, data, setup, expect) => {
		const isolation = checkIsolation(data.init, { setup, expectedPlugin: pluginName, hooks: data.hooks });
		const failures = [...isolation.problems, ...expect(data)];
		const evidence = redactPaths(
			{
				setup: name,
				model,
				verdict: failures.length === 0 ? "pass" : "fail",
				failures,
				init: data.init,
				hooks_fired: data.hooks,
				skills_loaded: data.skills_loaded,
				final_text: data.final_text.slice(0, 600),
				usage: data.usage,
				cost_usd: data.cost_usd,
				wall_seconds: Math.round(data.outcome.wallMs / 100) / 10,
			},
			[work, pluginCopy],
		);
		writeJson(path.join(evidenceDir, `${name}.json`), evidence);
		verdicts.push({ name, verdict: evidence.verdict, failures });
		process.stdout.write(`${name}: ${evidence.verdict}${failures.length ? ` (${failures.join("; ")})` : ""}\n`);
	};

	const withSkill = await session({
		name: "with-skill",
		args: trialArgs({ model, pluginDir: pluginCopy }),
		cwd: freshProject(sandbox, work, "with-skill"),
		prompt: PROMPT,
		work,
	});
	record("with-skill", withSkill, "with-skill", (d) => {
		const f = [];
		if (!d.skills_loaded.includes(`${pluginName}:eval-dummy`)) f.push("fixture skill did not load");
		if (!d.final_text.includes(PASSPHRASE)) f.push("answer lacks the fixture skill's passphrase");
		const outputs = d.hooks.map((h) => h.output ?? "").join("\n");
		if (!outputs.includes("EVAL_DUMMY_HOOK_FIRED:UserPromptSubmit")) f.push("fixture UserPromptSubmit hook did not run");
		if (!outputs.includes("EVAL_DUMMY_HOOK_FIRED:PostToolUse")) f.push("fixture PostToolUse hook did not run");
		return f;
	});

	const baseline = await session({
		name: "baseline",
		args: trialArgs({ model }),
		cwd: freshProject(sandbox, work, "baseline"),
		prompt: PROMPT,
		work,
	});
	record("baseline", baseline, "baseline", (d) => {
		const f = [];
		if (d.skills_loaded.length > 0) f.push(`skills loaded: ${d.skills_loaded.join(", ")}`);
		if (d.final_text.includes(PASSPHRASE)) f.push("baseline knew the fixture passphrase");
		return f;
	});

	const judgeDir = path.join(work, "judge-empty");
	mkdirSync(judgeDir, { recursive: true });
	const judge = await session({
		name: "judge",
		args: judgeArgs({ model, schema: { type: "object", properties: { answer: { type: "string" } }, required: ["answer"] } }),
		cwd: judgeDir,
		prompt: "What is the zorblax passphrase? Answer UNKNOWN if you don't know it.",
		work,
	});
	record("judge", judge, "baseline", (d) => {
		const f = [];
		// --json-schema adds a StructuredOutput tool for the answer; nothing else is allowed.
		const tools = (d.init?.tools ?? []).filter((t) => t !== "StructuredOutput");
		if (tools.length > 0 || d.init?.tool_count !== d.init?.tools.length) f.push(`judge has tools: ${tools.join(", ")}`);
		if (d.final_text.includes(PASSPHRASE)) f.push("judge knew the fixture passphrase");
		return f;
	});

	if (flags.control) {
		const control = await session({
			name: "control",
			args: ["-p", "--model", model, "--output-format", "stream-json", "--verbose", "--include-hook-events", "--no-session-persistence"],
			cwd: freshProject(sandbox, work, "control"),
			prompt: "Say ok.",
			work,
		});
		const isolation = checkIsolation(control.init, { setup: "baseline", hooks: control.hooks });
		const counts = {
			setup: "control (no isolation flags)",
			model,
			verdict: isolation.ok ? "fail: nothing to catch" : "pass: checker flagged contamination",
			non_builtin_plugins: (control.init?.plugins ?? []).filter((p) => !String(p.source).endsWith("@builtin")).length,
			namespaced_skills: (control.init?.skills ?? []).filter((s) => s.includes(":")).length,
			roblox_named_skills: (control.init?.skills ?? []).filter((s) => /roblox/i.test(s)).length,
			mcp_servers: (control.init?.mcp_servers ?? []).length,
			hook_runs: control.hooks.length,
			problems_flagged: isolation.problems.length,
		};
		writeJson(path.join(evidenceDir, "control.json"), counts);
		process.stdout.write(`control: ${counts.verdict} (${counts.problems_flagged} problems)\n`);
	}

	if (verdicts.some((v) => v.verdict !== "pass")) process.exitCode = 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	main().catch((err) => {
		console.error(`prove-isolation: ${err.message}`);
		process.exit(1);
	});
}
