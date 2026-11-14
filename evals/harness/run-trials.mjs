#!/usr/bin/env node
// Runs eval trials: each trial is a headless `claude -p` session in its own copy of
// the sandbox, under one setup.
//
//   node evals/harness/run-trials.mjs --task <file>[,<file>...] --sandbox <dir> --out <dir>
//     [--setup with-skill|baseline|both] [--runs 3] [--concurrency 5]
//     [--plugin-dir plugins/roblox-dev] [--model opus] [--effort <level>]
//     [--timeout-minutes <n>] [--max-budget-usd <n>] [--disable-plugins a@m,b@m] [--keep-projects]
//
// Layout (what skill-creator's aggregate_benchmark.py reads):
//   <out>/eval-<id>-<name>/eval_metadata.json
//   <out>/eval-<id>-<name>/<with_skill|without_skill>/run-<n>/
//     run.json  grading.json  timing.json  metrics.json  transcript.jsonl  stderr.log
//     outputs/changes.diff  outputs/files/...

import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { intFlag, listFlag, parseArgs } from "./lib/args.mjs";
import { buildGrading, LUAU, runAutoChecks, runTaskChecks } from "./lib/checks.mjs";
import { runClaude, trialArgs } from "./lib/claude.mjs";
import { checkIsolation, CONFIG_DIR, readPluginName, SETUPS } from "./lib/isolation.mjs";
import { runPool } from "./lib/pool.mjs";
import {
	findInit,
	findResult,
	finalText,
	hooksFired,
	parseEvents,
	skillFileReads,
	skillsLoaded,
	summarizeInit,
	summarizeResult,
	toolCallCounts,
	usageTotals,
} from "./lib/stream.mjs";
import { loadTask } from "./lib/task.mjs";
import {
	ancestorMemoryFiles,
	applySetupFiles,
	changedFiles,
	copySandbox,
	diffAgainst,
	headCommit,
	saveChangedFiles,
	writeJson,
} from "./lib/workspace.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_PLUGIN = path.resolve(HERE, "..", "..", "plugins", "roblox-dev");

export const COMPLETION_CHECK = "The trial finished without an error or timeout";

export function trialStatus({ outcome, result, isolation }) {
	if (outcome.spawnError) return "failed";
	if (outcome.timedOut) return "timeout";
	if (!isolation.ok) return "contaminated";
	if (!result || result.is_error || outcome.exitCode !== 0) return "failed";
	return "ok";
}

function nextRunNumber(configDir) {
	if (!existsSync(configDir)) return 1;
	const used = readdirSync(configDir)
		.map((d) => /^run-(\d+)$/.exec(d))
		.filter(Boolean)
		.map((m) => Number(m[1]));
	return used.length ? Math.max(...used) + 1 : 1;
}

function evalDirName(task) {
	return `eval-${task.id}-${task.name}`;
}

async function runTrial({ task, setup, runNumber, opts }) {
	const evalDir = path.join(opts.out, evalDirName(task));
	const trialDir = path.join(evalDir, CONFIG_DIR[setup], `run-${runNumber}`);
	const projectDir = path.join(trialDir, "project");
	const label = `${evalDirName(task)} ${setup} run-${runNumber}`;
	mkdirSync(trialDir, { recursive: true });

	const record = { task: task.name, eval_id: task.id, setup, run: runNumber, status: "failed", error: null };
	let outcome = { exitCode: null, spawnError: null, timedOut: false, wallMs: 0, startedAt: null, endedAt: null };
	let events = [];
	try {
		copySandbox(opts.sandbox, projectDir);
		applySetupFiles(task, projectDir);
		const base = headCommit(projectDir);
		let pluginCopy = null;
		if (setup === "with-skill") {
			pluginCopy = path.join(trialDir, "plugin", path.basename(opts.pluginDir));
			cpSync(opts.pluginDir, pluginCopy, { recursive: true });
		}
		process.stdout.write(`start  ${label}\n`);
		outcome = await runClaude({
			args: trialArgs({
				model: opts.model,
				pluginDir: pluginCopy,
				effort: opts.effort,
				maxBudgetUsd: opts.maxBudgetUsd,
				extraDisabledPlugins: opts.disablePlugins,
			}),
			prompt: task.prompt,
			cwd: projectDir,
			transcriptPath: path.join(trialDir, "transcript.jsonl"),
			stderrPath: path.join(trialDir, "stderr.log"),
			timeoutMs: (opts.timeoutMinutes ?? task.timeout_minutes) * 60_000,
		});
		events = parseEvents(readFileSync(path.join(trialDir, "transcript.jsonl"), "utf8"));

		const init = summarizeInit(findInit(events));
		const result = findResult(events);
		const hooks = hooksFired(events);
		const isolation = checkIsolation(init, { setup, expectedPlugin: opts.pluginName, hooks });
		const usage = usageTotals(result);
		const loaded = skillsLoaded(events);
		const status = trialStatus({ outcome, result, isolation });

		const { changed, deleted } = changedFiles(projectDir, base);
		mkdirSync(path.join(trialDir, "outputs"), { recursive: true });
		writeFileSync(path.join(trialDir, "outputs", "changes.diff"), diffAgainst(projectDir, base));
		saveChangedFiles(projectDir, changed, path.join(trialDir, "outputs", "files"));
		writeFileSync(path.join(trialDir, "outputs", "final-message.md"), finalText(result));

		const changedLuau = changed.filter((f) => LUAU.test(f));
		const expectations = [
			{ text: COMPLETION_CHECK, passed: status === "ok", evidence: `status ${status}${outcome.timedOut ? " (killed at timeout)" : ""}` },
			...runAutoChecks({ projectDir, changedLuau, autoChecks: task.auto_checks }),
			...runTaskChecks({ projectDir, checks: task.checks }),
		];
		const toolCalls = toolCallCounts(events);
		const grading = buildGrading(
			expectations,
			{
				tool_calls: toolCalls,
				total_tool_calls: Object.values(toolCalls).reduce((a, b) => a + b, 0),
				total_steps: result?.num_turns ?? 0,
				errors_encountered: status === "ok" ? 0 : 1,
				output_chars: finalText(result).length,
			},
			{ needs_review: status === "ok" ? [] : [`trial status: ${status}`] },
		);
		writeJson(path.join(trialDir, "grading.json"), grading);
		writeJson(path.join(trialDir, "timing.json"), {
			total_tokens: usage.total_tokens,
			duration_ms: outcome.wallMs,
			total_duration_seconds: Math.round(outcome.wallMs / 100) / 10,
			executor_start: outcome.startedAt,
			executor_end: outcome.endedAt,
			executor_duration_seconds: Math.round(outcome.wallMs / 100) / 10,
		});
		writeJson(path.join(trialDir, "metrics.json"), {
			init,
			isolation,
			skills_loaded: loaded,
			skill_file_reads: skillFileReads(events),
			hooks_fired: hooks,
			tool_calls: toolCalls,
			usage,
			result: summarizeResult(result),
		});
		Object.assign(record, {
			status,
			isolation_ok: isolation.ok,
			isolation_problems: isolation.problems,
			model: init?.model ?? null,
			skills_loaded: loaded,
			target_skill: task.skill ? `${opts.pluginName}:${task.skill}` : null,
			target_skill_loaded: task.skill ? loaded.includes(`${opts.pluginName}:${task.skill}`) : null,
			hooks_fired: [...new Set(hooks.map((h) => h.hook_name))],
			changed_files: changed,
			deleted_files: deleted,
			pass_rate: grading.summary.pass_rate,
			tokens: usage,
			cost_usd: result?.total_cost_usd ?? null,
			num_turns: result?.num_turns ?? null,
			wall_seconds: Math.round(outcome.wallMs / 100) / 10,
			exit_code: outcome.exitCode,
			timed_out: outcome.timedOut,
			spawn_error: outcome.spawnError,
			base_commit: base,
		});
	} catch (err) {
		record.error = err.message;
		// A trial that breaks before grading still leaves a grading.json, so the
		// aggregate counts it as a failure instead of skipping it.
		writeJson(
			path.join(trialDir, "grading.json"),
			buildGrading([{ text: COMPLETION_CHECK, passed: false, evidence: `harness error: ${err.message}` }], {}, { needs_review: [`harness error: ${err.message}`] }),
		);
		writeJson(path.join(trialDir, "timing.json"), { total_tokens: 0, duration_ms: outcome.wallMs, total_duration_seconds: Math.round(outcome.wallMs / 100) / 10 });
	}
	writeJson(path.join(trialDir, "run.json"), record);
	if (!opts.keepProjects) {
		rmSync(projectDir, { recursive: true, force: true });
		rmSync(path.join(trialDir, "plugin"), { recursive: true, force: true });
	}
	process.stdout.write(
		`done   ${label}: ${record.status}${record.error ? ` (${record.error})` : ""}` +
			` pass=${record.pass_rate ?? 0} tokens=${record.tokens?.total_tokens ?? 0} cost=$${record.cost_usd ?? 0} wall=${record.wall_seconds ?? 0}s` +
			`${record.isolation_problems?.length ? ` ISOLATION: ${record.isolation_problems.join("; ")}` : ""}\n`,
	);
	return record;
}

async function main() {
	const { flags } = parseArgs(process.argv.slice(2), { booleans: ["keep-projects"] });
	const taskFiles = listFlag(flags.task);
	if (taskFiles.length === 0 || !flags.sandbox || !flags.out) {
		console.error("usage: node evals/harness/run-trials.mjs --task <file>[,<file>] --sandbox <dir> --out <dir> [--setup both] [--runs 3] [--concurrency 5]");
		process.exit(2);
	}
	const setupFlag = flags.setup ?? "both";
	const setups = setupFlag === "both" ? SETUPS : [setupFlag];
	if (!setups.every((s) => SETUPS.includes(s))) throw new Error(`--setup must be with-skill, baseline, or both`);

	const opts = {
		sandbox: path.resolve(flags.sandbox),
		out: path.resolve(flags.out),
		pluginDir: path.resolve(flags["plugin-dir"] ?? DEFAULT_PLUGIN),
		model: flags.model ?? "opus",
		effort: flags.effort ?? null,
		timeoutMinutes: flags["timeout-minutes"] ? Number(flags["timeout-minutes"]) : null,
		maxBudgetUsd: flags["max-budget-usd"] ? Number(flags["max-budget-usd"]) : null,
		disablePlugins: listFlag(flags["disable-plugins"]),
		keepProjects: !!flags["keep-projects"],
	};
	const runs = intFlag(flags.runs, "runs", { max: 50, fallback: 3 });
	const concurrency = intFlag(flags.concurrency, "concurrency", { max: 20, fallback: 5 });
	if (!existsSync(path.join(opts.sandbox, ".git"))) throw new Error(`${opts.sandbox} is not a sandbox (run build-sandbox.mjs first)`);
	const memory = ancestorMemoryFiles(opts.out);
	if (memory.length > 0) throw new Error(`a CLAUDE.md above ${opts.out} would load into every trial: ${memory.join(", ")}`);
	opts.pluginName = setups.includes("with-skill") ? readPluginName(opts.pluginDir) : null;

	const tasks = taskFiles.map(loadTask);
	const jobs = [];
	for (const task of tasks) {
		const evalDir = path.join(opts.out, evalDirName(task));
		writeJson(path.join(evalDir, "eval_metadata.json"), {
			eval_id: task.id,
			eval_name: task.name,
			prompt: task.prompt,
			skill: task.skill ?? null,
			rubric: task.rubric,
			task_file: task.file,
		});
		for (const setup of setups) {
			const first = nextRunNumber(path.join(evalDir, CONFIG_DIR[setup]));
			for (let i = 0; i < runs; i++) {
				jobs.push(() => runTrial({ task, setup, runNumber: first + i, opts }));
			}
		}
	}
	process.stdout.write(`Running ${jobs.length} trials, ${concurrency} at a time, model ${opts.model}\n`);
	const records = await runPool(jobs, concurrency);
	const counts = {};
	for (const r of records) counts[r.status ?? "error"] = (counts[r.status ?? "error"] ?? 0) + 1;
	process.stdout.write(`Finished: ${JSON.stringify(counts)}\n`);
	if (counts.contaminated) {
		process.stdout.write("WARNING: contaminated trials saw plugins, skills, or MCP servers outside their setup. See run.json.\n");
		process.exitCode = 3;
	}
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	main().catch((err) => {
		console.error(`run-trials: ${err.message}`);
		process.exit(1);
	});
}
