#!/usr/bin/env node
// Blind judge: for each task, pairs with-skill run-i with baseline run-i, shows them
// to an Opus judge as A and B in random order, and records the mapping where the
// judge can't see it (the judge gets no tools; both outputs are in its prompt).
//
//   node evals/harness/judge.mjs --results <dir> [--pairs <n>] [--concurrency 5] [--model opus]
//
// Writes <results>/eval-*/judge/pair-<i>/{prompt.md,mapping.json,comparison.json,
// transcript.jsonl,timing.json,metrics.json} and <results>/judge-summary.json.

import { randomInt } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { intFlag, parseArgs } from "./lib/args.mjs";
import { judgeArgs, runClaude } from "./lib/claude.mjs";
import { checkIsolation, CONFIG_DIR } from "./lib/isolation.mjs";
import { runPool } from "./lib/pool.mjs";
import { findInit, findResult, hooksFired, parseEvents, summarizeInit, usageTotals } from "./lib/stream.mjs";
import { readJson, writeJson } from "./lib/workspace.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MAX_DIFF_CHARS = 60_000;
const WITH = CONFIG_DIR["with-skill"];
const BASE = CONFIG_DIR.baseline;

const criterionSchema = {
	type: "object",
	properties: {
		criterion: { type: "string" },
		score: { type: "integer", minimum: 1, maximum: 5 },
		note: { type: "string" },
	},
	required: ["criterion", "score", "note"],
};
const attemptSchema = {
	type: "object",
	properties: {
		criteria: { type: "array", items: criterionSchema },
		overall_score: { type: "number", minimum: 1, maximum: 10 },
		strengths: { type: "array", items: { type: "string" } },
		weaknesses: { type: "array", items: { type: "string" } },
	},
	required: ["criteria", "overall_score", "strengths", "weaknesses"],
};
export const JUDGE_SCHEMA = {
	type: "object",
	properties: {
		A: attemptSchema,
		B: attemptSchema,
		winner: { type: "string", enum: ["A", "B", "TIE"] },
		reasoning: { type: "string" },
	},
	required: ["A", "B", "winner", "reasoning"],
};

// Removes the plugin's skill names from what the judge sees, so a comment such as
// "per roblox-dev:vide" can't reveal which attempt had the skill.
export function scrub(text, pluginName = "roblox-dev") {
	const escaped = pluginName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	return String(text).replace(new RegExp(`${escaped}:[a-z0-9-]+`, "g"), "<skill>");
}

function attemptText(runDir) {
	const diffFile = path.join(runDir, "outputs", "changes.diff");
	let diff = existsSync(diffFile) ? readFileSync(diffFile, "utf8") : "";
	if (!diff.trim()) diff = "(no changes)";
	if (diff.length > MAX_DIFF_CHARS) diff = `${diff.slice(0, MAX_DIFF_CHARS)}\n... (diff truncated)`;
	const grading = existsSync(path.join(runDir, "grading.json")) ? readJson(path.join(runDir, "grading.json")) : { expectations: [] };
	const checks = grading.expectations.map((e) => `- [${e.passed ? "pass" : "fail"}] ${e.text}${e.passed ? "" : `\n  ${String(e.evidence).split("\n").slice(0, 12).join("\n  ")}`}`).join("\n");
	return { diff: scrub(diff), checks: scrub(checks || "(no checks)") };
}

export function fillTemplate(template, values) {
	return template.replace(/\{\{([A-Z_]+)\}\}/g, (match, key) => (key in values ? values[key] : match));
}

// Picks which run is A with a cryptographic coin flip.
export function assignLabels(withRun, baseRun, flip = randomInt(2)) {
	return flip === 0 ? { A: withRun, B: baseRun } : { A: baseRun, B: withRun };
}

function runsOf(evalDir, config) {
	const dir = path.join(evalDir, config);
	if (!existsSync(dir)) return new Map();
	const runs = new Map();
	for (const name of readdirSync(dir)) {
		const m = /^run-(\d+)$/.exec(name);
		if (!m) continue;
		const runJson = path.join(dir, name, "run.json");
		const record = existsSync(runJson) ? readJson(runJson) : { status: "missing" };
		runs.set(Number(m[1]), { dir: path.join(dir, name), id: `${config}/${name}`, record });
	}
	return runs;
}

async function judgePair({ evalDir, meta, pairIndex, withRun, baseRun, opts, template }) {
	const pairDir = path.join(evalDir, "judge", `pair-${pairIndex}`);
	mkdirSync(pairDir, { recursive: true });
	const labels = assignLabels(withRun, baseRun);
	const a = attemptText(labels.A.dir);
	const b = attemptText(labels.B.dir);
	const prompt = fillTemplate(template, {
		TASK_PROMPT: meta.prompt,
		RUBRIC: meta.rubric.map((c, i) => `${i + 1}. ${c}`).join("\n"),
		CHECKS_A: a.checks,
		OUTPUT_A: a.diff,
		CHECKS_B: b.checks,
		OUTPUT_B: b.diff,
	});
	writeFileSync(path.join(pairDir, "prompt.md"), prompt);
	writeJson(path.join(pairDir, "mapping.json"), { A: labels.A.id, B: labels.B.id });

	const judgeCwd = path.join(opts.workRoot, `${path.basename(evalDir)}-pair-${pairIndex}`);
	mkdirSync(judgeCwd, { recursive: true });
	const outcome = await runClaude({
		args: judgeArgs({ model: opts.model, schema: JUDGE_SCHEMA, effort: opts.effort }),
		prompt,
		cwd: judgeCwd,
		transcriptPath: path.join(pairDir, "transcript.jsonl"),
		stderrPath: path.join(pairDir, "stderr.log"),
		timeoutMs: opts.timeoutMinutes * 60_000,
	});
	const events = parseEvents(readFileSync(path.join(pairDir, "transcript.jsonl"), "utf8"));
	const result = findResult(events);
	const init = summarizeInit(findInit(events));
	const isolation = checkIsolation(init, { setup: "baseline", hooks: hooksFired(events) });
	const extraTools = (init?.tools ?? []).filter((t) => t !== "StructuredOutput");
	if (extraTools.length) isolation.problems.push(`judge had tools: ${extraTools.join(", ")}`);
	isolation.ok = isolation.problems.length === 0;
	const usage = usageTotals(result);
	writeJson(path.join(pairDir, "timing.json"), {
		total_tokens: usage.total_tokens,
		duration_ms: outcome.wallMs,
		total_duration_seconds: Math.round(outcome.wallMs / 100) / 10,
	});
	writeJson(path.join(pairDir, "metrics.json"), { init, isolation, usage, cost_usd: result?.total_cost_usd ?? null, outcome });

	const verdict = result?.structured_output;
	if (!verdict || outcome.timedOut || !isolation.ok) {
		const status = outcome.timedOut ? "timeout" : !isolation.ok ? "contaminated" : "failed";
		const record = { pair: pairIndex, status, mapping: { A: labels.A.id, B: labels.B.id }, isolation_problems: isolation.problems };
		writeJson(path.join(pairDir, "comparison.json"), record);
		return { ...record, tokens: usage.total_tokens, wall_seconds: outcome.wallMs / 1000, cost_usd: result?.total_cost_usd ?? null };
	}
	const configOf = (label) => (labels[label] === withRun ? WITH : BASE);
	const comparison = {
		pair: pairIndex,
		status: "ok",
		winner: verdict.winner,
		winner_config: verdict.winner === "TIE" ? "TIE" : configOf(verdict.winner),
		reasoning: verdict.reasoning,
		rubric: {
			A: { criteria: verdict.A.criteria, overall_score: verdict.A.overall_score },
			B: { criteria: verdict.B.criteria, overall_score: verdict.B.overall_score },
		},
		output_quality: {
			A: { score: verdict.A.overall_score, strengths: verdict.A.strengths, weaknesses: verdict.A.weaknesses },
			B: { score: verdict.B.overall_score, strengths: verdict.B.strengths, weaknesses: verdict.B.weaknesses },
		},
		scores_by_config: { [configOf("A")]: verdict.A.overall_score, [configOf("B")]: verdict.B.overall_score },
		mapping: { A: labels.A.id, B: labels.B.id },
	};
	writeJson(path.join(pairDir, "comparison.json"), comparison);
	return { ...comparison, tokens: usage.total_tokens, wall_seconds: outcome.wallMs / 1000, cost_usd: result?.total_cost_usd ?? null };
}

const mean = (xs) => (xs.length ? Math.round((xs.reduce((a, b) => a + b, 0) / xs.length) * 100) / 100 : null);

export function summarizeJudgements(perEval) {
	const summary = { evals: {}, totals: { pairs: 0, judged: 0, [WITH]: 0, [BASE]: 0, TIE: 0 } };
	const allWith = [];
	const allBase = [];
	for (const [evalName, results] of Object.entries(perEval)) {
		const ok = results.filter((r) => r.status === "ok");
		const wins = { [WITH]: 0, [BASE]: 0, TIE: 0 };
		for (const r of ok) wins[r.winner_config]++;
		const withScores = ok.map((r) => r.scores_by_config[WITH]);
		const baseScores = ok.map((r) => r.scores_by_config[BASE]);
		allWith.push(...withScores);
		allBase.push(...baseScores);
		summary.evals[evalName] = {
			pairs: results.length,
			judged: ok.length,
			not_judged: results.filter((r) => r.status !== "ok").map((r) => ({ pair: r.pair, status: r.status })),
			wins,
			mean_score: { [WITH]: mean(withScores), [BASE]: mean(baseScores) },
		};
		summary.totals.pairs += results.length;
		summary.totals.judged += ok.length;
		for (const k of [WITH, BASE, "TIE"]) summary.totals[k] += wins[k];
	}
	summary.totals.mean_score = { [WITH]: mean(allWith), [BASE]: mean(allBase) };
	const all = Object.values(perEval).flat();
	summary.judge_cost = {
		runs: all.length,
		mean_tokens: mean(all.map((r) => r.tokens ?? 0)),
		mean_wall_seconds: mean(all.map((r) => r.wall_seconds ?? 0)),
		total_cost_usd: Math.round(all.reduce((a, r) => a + (r.cost_usd ?? 0), 0) * 10000) / 10000,
	};
	return summary;
}

async function main() {
	const { flags } = parseArgs(process.argv.slice(2));
	if (!flags.results) {
		console.error("usage: node evals/harness/judge.mjs --results <dir> [--pairs <n>] [--concurrency 5]");
		process.exit(2);
	}
	const results = path.resolve(flags.results);
	const opts = {
		model: flags.model ?? "opus",
		effort: flags.effort ?? null,
		timeoutMinutes: Number(flags["timeout-minutes"] ?? 10),
		workRoot: path.join(results, ".judge-work"),
	};
	const maxPairs = intFlag(flags.pairs, "pairs", { max: 100, fallback: 100 });
	const concurrency = intFlag(flags.concurrency, "concurrency", { max: 20, fallback: 5 });
	const template = readFileSync(path.join(HERE, "judge-prompt.md"), "utf8");

	const jobs = [];
	const owners = [];
	const skipped = [];
	for (const name of readdirSync(results).filter((d) => d.startsWith("eval-")).sort()) {
		const evalDir = path.join(results, name);
		const meta = readJson(path.join(evalDir, "eval_metadata.json"));
		const withRuns = runsOf(evalDir, WITH);
		const baseRuns = runsOf(evalDir, BASE);
		const shared = [...withRuns.keys()].filter((n) => baseRuns.has(n)).sort((x, y) => x - y).slice(0, maxPairs);
		for (const n of shared) {
			const w = withRuns.get(n);
			const b = baseRuns.get(n);
			if (w.record.status === "contaminated" || b.record.status === "contaminated") {
				skipped.push({ eval: name, pair: n, reason: "contaminated trial" });
				continue;
			}
			owners.push(name);
			jobs.push(() => judgePair({ evalDir, meta, pairIndex: n, withRun: w, baseRun: b, opts, template }));
		}
	}
	process.stdout.write(`Judging ${jobs.length} pairs, ${concurrency} at a time\n`);
	const outcomes = await runPool(jobs, concurrency);
	const perEval = {};
	outcomes.forEach((o, i) => {
		(perEval[owners[i]] ??= []).push(o.error ? { status: "failed", error: o.error } : o);
		process.stdout.write(`${owners[i]} pair-${o.pair ?? "?"}: ${o.status ?? "failed"}${o.winner_config ? ` winner=${o.winner_config}` : ""}\n`);
	});
	const summary = { ...summarizeJudgements(perEval), skipped };
	writeJson(path.join(results, "judge-summary.json"), summary);
	process.stdout.write(`Wrote ${path.join(results, "judge-summary.json")}\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	main().catch((err) => {
		console.error(`judge: ${err.message}`);
		process.exit(1);
	});
}
