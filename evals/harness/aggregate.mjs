#!/usr/bin/env node
// Aggregates a results folder: runs skill-creator's aggregate_benchmark.py (pass
// rate, time, and tokens as mean and stddev per setup, with the with-skill minus
// baseline delta), then adds what that script doesn't know about: trial statuses,
// whether the target skill loaded, cost, and the blind judge's verdicts.
//
//   node evals/harness/aggregate.mjs --results <dir> [--skill-name <name>] [--skill-path <path>]
//     [--allow-contaminated]

import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { parseArgs, skillCreatorDir } from "./lib/args.mjs";
import { CONFIG_DIR } from "./lib/isolation.mjs";
import { readJson, writeJson } from "./lib/workspace.mjs";

const WITH = CONFIG_DIR["with-skill"];
const BASE = CONFIG_DIR.baseline;

function stats(values) {
	if (values.length === 0) return { mean: 0, stddev: 0, min: 0, max: 0 };
	const n = values.length;
	const mean = values.reduce((a, b) => a + b, 0) / n;
	const stddev = n > 1 ? Math.sqrt(values.reduce((a, x) => a + (x - mean) ** 2, 0) / (n - 1)) : 0;
	const r = (x) => Math.round(x * 10000) / 10000;
	return { mean: r(mean), stddev: r(stddev), min: r(Math.min(...values)), max: r(Math.max(...values)) };
}

export function collectRuns(results) {
	const runs = [];
	for (const evalName of readdirSync(results).filter((d) => d.startsWith("eval-")).sort()) {
		for (const config of [WITH, BASE]) {
			const dir = path.join(results, evalName, config);
			if (!existsSync(dir)) continue;
			for (const run of readdirSync(dir).filter((d) => /^run-\d+$/.test(d))) {
				const file = path.join(dir, run, "run.json");
				const record = existsSync(file) ? readJson(file) : { status: "missing" };
				runs.push({ eval: evalName, config, run, ...record });
			}
		}
	}
	return runs;
}

export function harnessSummary(runs) {
	const byConfig = {};
	for (const config of [WITH, BASE]) {
		const mine = runs.filter((r) => r.config === config);
		const statuses = {};
		for (const r of mine) statuses[r.status ?? "missing"] = (statuses[r.status ?? "missing"] ?? 0) + 1;
		const withTarget = mine.filter((r) => r.target_skill);
		byConfig[config] = {
			trials: mine.length,
			statuses,
			target_skill_loaded: withTarget.length ? `${withTarget.filter((r) => r.target_skill_loaded).length}/${withTarget.length}` : null,
			tokens: stats(mine.map((r) => r.tokens?.total_tokens ?? 0)),
			output_tokens: stats(mine.map((r) => r.tokens?.output_tokens ?? 0)),
			wall_seconds: stats(mine.map((r) => r.wall_seconds ?? 0)),
			cost_usd: stats(mine.map((r) => r.cost_usd ?? 0)),
			total_cost_usd: Math.round(mine.reduce((a, r) => a + (r.cost_usd ?? 0), 0) * 10000) / 10000,
		};
	}
	return byConfig;
}

function markdownSections(harness, runs, judge) {
	const lines = ["", "## Trials", "", "| Setup | Trials | Statuses | Target skill loaded | Tokens (mean ± sd) | Wall s (mean ± sd) | Cost $ (mean, total) |", "|---|---|---|---|---|---|---|"];
	for (const [config, h] of Object.entries(harness)) {
		lines.push(
			`| ${config} | ${h.trials} | ${Object.entries(h.statuses).map(([k, v]) => `${k} ${v}`).join(", ")} | ${h.target_skill_loaded ?? "n/a"} | ${Math.round(h.tokens.mean)} ± ${Math.round(h.tokens.stddev)} | ${h.wall_seconds.mean.toFixed(1)} ± ${h.wall_seconds.stddev.toFixed(1)} | ${h.cost_usd.mean.toFixed(4)}, ${h.total_cost_usd.toFixed(4)} |`,
		);
	}
	lines.push("", "Tokens count input, output, and cache reads and writes across every model the session used.", "", "## Per trial", "", "| Eval | Setup | Run | Status | Pass rate | Skills loaded | Tokens | Output tokens | Wall s | Cost $ |", "|---|---|---|---|---|---|---|---|---|---|");
	for (const r of runs) {
		lines.push(
			`| ${r.eval} | ${r.config} | ${r.run} | ${r.status} | ${r.pass_rate ?? 0} | ${(r.skills_loaded ?? []).join(", ") || "none"} | ${r.tokens?.total_tokens ?? 0} | ${r.tokens?.output_tokens ?? 0} | ${r.wall_seconds ?? 0} | ${(r.cost_usd ?? 0).toFixed(4)} |`,
		);
	}
	if (judge) {
		lines.push("", "## Blind judge", "", "| Eval | Pairs judged | with_skill wins | without_skill wins | Ties | Mean score with_skill | Mean score without_skill |", "|---|---|---|---|---|---|---|");
		for (const [name, e] of Object.entries(judge.evals)) {
			lines.push(`| ${name} | ${e.judged}/${e.pairs} | ${e.wins[WITH]} | ${e.wins[BASE]} | ${e.wins.TIE} | ${e.mean_score[WITH] ?? "-"} | ${e.mean_score[BASE] ?? "-"} |`);
		}
		const t = judge.totals;
		lines.push(`| **All** | ${t.judged}/${t.pairs} | ${t[WITH]} | ${t[BASE]} | ${t.TIE} | ${t.mean_score[WITH] ?? "-"} | ${t.mean_score[BASE] ?? "-"} |`);
		const c = judge.judge_cost;
		lines.push("", `Judge runs: ${c.runs}, mean ${Math.round(c.mean_tokens ?? 0)} tokens and ${c.mean_wall_seconds ?? 0} s each, $${c.total_cost_usd} in total.`);
	}
	return lines.join("\n");
}

async function main() {
	const { flags } = parseArgs(process.argv.slice(2), { booleans: ["allow-contaminated"] });
	if (!flags.results) {
		console.error("usage: node evals/harness/aggregate.mjs --results <dir> [--skill-name <name>] [--skill-path <path>]");
		process.exit(2);
	}
	const results = path.resolve(flags.results);
	const runs = collectRuns(results);
	if (runs.length === 0) throw new Error(`no trials under ${results}`);
	const contaminated = runs.filter((r) => r.status === "contaminated");
	if (contaminated.length > 0 && !flags["allow-contaminated"]) {
		throw new Error(`${contaminated.length} contaminated trial(s); fix isolation and rerun, or pass --allow-contaminated`);
	}

	const scDir = skillCreatorDir();
	const py = process.env.PYTHON ?? (process.platform === "win32" ? "python" : "python3");
	const args = ["-m", "scripts.aggregate_benchmark", results];
	if (flags["skill-name"]) args.push("--skill-name", flags["skill-name"]);
	if (flags["skill-path"]) args.push("--skill-path", flags["skill-path"]);
	const res = spawnSync(py, args, { cwd: scDir, encoding: "utf8", env: { ...process.env, PYTHONUTF8: "1" } });
	if (res.error || res.status !== 0) throw new Error(`aggregate_benchmark.py failed: ${res.error?.message ?? res.stderr}`);
	process.stdout.write(res.stdout);

	const benchmarkFile = path.join(results, "benchmark.json");
	const benchmark = readJson(benchmarkFile);
	const models = [...new Set(runs.map((r) => r.model).filter(Boolean))];
	const runCounts = runs.reduce((acc, r) => ((acc[`${r.eval}/${r.config}`] = (acc[`${r.eval}/${r.config}`] ?? 0) + 1), acc), {});
	benchmark.metadata.executor_model = models.join(", ") || "unknown";
	benchmark.metadata.runs_per_configuration = Math.max(...Object.values(runCounts));
	const judgeFile = path.join(results, "judge-summary.json");
	const judge = existsSync(judgeFile) ? readJson(judgeFile) : null;
	if (judge) benchmark.metadata.analyzer_model = "judge: see judge-summary.json";
	benchmark.harness = harnessSummary(runs);
	if (judge) benchmark.judge = judge;
	writeJson(benchmarkFile, benchmark);

	// aggregate_benchmark.py writes placeholders for the model and a fixed run count.
	const md = readFileSync(path.join(results, "benchmark.md"), "utf8")
		.replace("**Model**: <model-name>", `**Model**: ${benchmark.metadata.executor_model}`)
		.replace(/(\*\*Evals\*\*: .*\()3 runs each/, `$1${benchmark.metadata.runs_per_configuration} runs each`);
	writeFileSync(path.join(results, "benchmark.md"), `${md}\n${markdownSections(benchmark.harness, runs, judge)}\n`);
	process.stdout.write(`Updated ${benchmarkFile} and benchmark.md\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	main().catch((err) => {
		console.error(`aggregate: ${err.message}`);
		process.exit(1);
	});
}
