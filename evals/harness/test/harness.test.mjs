import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { after, describe, test } from "node:test";
import { fileURLToPath } from "node:url";

import { buildGrading, runTaskChecks, trimEvidence } from "../lib/checks.mjs";
import { childEnv, judgeArgs, trialArgs } from "../lib/claude.mjs";
import { checkIsolation, isolationArgs } from "../lib/isolation.mjs";
import { hooksFired, parseEvents, skillFileReads, skillsLoaded, usageTotals } from "../lib/stream.mjs";
import { loadTask, validateTask } from "../lib/task.mjs";
import { ancestorMemoryFiles, resolveInside } from "../lib/workspace.mjs";
import { redact } from "../export-results.mjs";
import { assignLabels, fillTemplate, scrub, summarizeJudgements } from "../judge.mjs";
import { redactPaths } from "../prove-isolation.mjs";
import { trialStatus } from "../run-trials.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const tmp = mkdtempSync(path.join(os.tmpdir(), "harness-test-"));
after(() => rmSync(tmp, { recursive: true, force: true }));

const builtin = [{ name: "cc-plugin-privacy", source: "cc-plugin-privacy@builtin", path: "builtin" }];
const cleanInit = (extra = {}) => ({
	plugins: builtin,
	skills: ["deep-research", "simplify"],
	agents: ["Explore", "Plan"],
	mcp_servers: [],
	tools: ["Read"],
	tool_count: 1,
	...extra,
});

describe("stream parsing", () => {
	const lines = [
		JSON.stringify({ type: "system", subtype: "init", plugins: [] }),
		"not json",
		JSON.stringify({ type: "system", subtype: "hook_started", hook_id: "h1", hook_name: "UserPromptSubmit", hook_event: "UserPromptSubmit" }),
		JSON.stringify({ type: "system", subtype: "hook_response", hook_id: "h1", hook_name: "UserPromptSubmit", hook_event: "UserPromptSubmit", exit_code: 0, output: "MARK" }),
		JSON.stringify({
			type: "assistant",
			message: {
				content: [
					{ type: "tool_use", name: "Skill", input: { skill: "roblox-dev:vide" } },
					{ type: "tool_use", name: "Read", input: { file_path: "C:/p/skills/vide/SKILL.md" } },
				],
			},
		}),
		JSON.stringify({
			type: "result",
			modelUsage: {
				a: { inputTokens: 1, outputTokens: 2, cacheReadInputTokens: 3, cacheCreationInputTokens: 4 },
				b: { inputTokens: 10, outputTokens: 0, cacheReadInputTokens: 0, cacheCreationInputTokens: 0 },
			},
		}),
		'{"type":"assistant","message":', // a trial killed mid-write
	].join("\n");
	const events = parseEvents(lines);

	test("skips lines that aren't JSON", () => assert.equal(events.length, 5));
	test("finds Skill tool loads and SKILL.md reads", () => {
		assert.deepEqual(skillsLoaded(events), ["roblox-dev:vide"]);
		assert.deepEqual(skillFileReads(events), ["C:/p/skills/vide/SKILL.md"]);
	});
	test("pairs hook start and response events", () => {
		assert.deepEqual(hooksFired(events), [{ hook_name: "UserPromptSubmit", hook_event: "UserPromptSubmit", exit_code: 0, output: "MARK" }]);
	});
	test("sums tokens across models", () => {
		const usage = usageTotals(events.at(-1));
		assert.equal(usage.total_tokens, 20);
		assert.equal(usage.input_tokens, 11);
	});
});

describe("isolation check", () => {
	test("accepts a clean baseline", () => {
		assert.deepEqual(checkIsolation(cleanInit(), { setup: "baseline" }), { ok: true, problems: [] });
	});

	test("accepts the plugin under test in with-skill", () => {
		const init = cleanInit({
			plugins: [...builtin, { name: "roblox-dev", source: "roblox-dev@inline" }],
			skills: ["roblox-dev:vide", "simplify"],
		});
		assert.equal(checkIsolation(init, { setup: "with-skill", expectedPlugin: "roblox-dev" }).ok, true);
	});

	test("flags a user-scope plugin with the same skills", () => {
		const init = cleanInit({
			plugins: [...builtin, { name: "roblox-dev", source: "roblox-dev@inline" }, { name: "roblox", source: "roblox@private" }],
			skills: ["roblox-dev:vide", "roblox:vide"],
			agents: ["roblox:reviewer"],
		});
		const res = checkIsolation(init, { setup: "with-skill", expectedPlugin: "roblox-dev" });
		assert.equal(res.ok, false);
		assert.ok(res.problems.some((p) => p.includes("roblox@private")));
		assert.ok(res.problems.some((p) => p.includes("roblox:vide")));
		assert.ok(res.problems.some((p) => p.includes("roblox:reviewer")));
	});

	test("flags the plugin under test, MCP servers, and hooks in the baseline", () => {
		const init = cleanInit({
			plugins: [...builtin, { name: "roblox-dev", source: "roblox-dev@inline" }],
			skills: ["roblox-dev:vide"],
			mcp_servers: [{ name: "studio" }],
		});
		const res = checkIsolation(init, { setup: "baseline", hooks: [{ hook_name: "SessionStart" }] });
		assert.equal(res.problems.length, 4);
	});

	test("flags with-skill when the plugin under test didn't load", () => {
		const res = checkIsolation(cleanInit(), { setup: "with-skill", expectedPlugin: "roblox-dev" });
		assert.equal(res.ok, false);
	});

	test("flags a missing init event", () => {
		assert.equal(checkIsolation(null, { setup: "baseline" }).ok, false);
	});
});

describe("claude arguments", () => {
	test("isolation flags drop user settings, MCP, user memory, and confine file tools", () => {
		const args = isolationArgs();
		assert.ok(args.includes("--restricted"));
		assert.equal(args[args.indexOf("--setting-sources") + 1], "project,local");
		assert.ok(args.includes("--strict-mcp-config"));
		const settings = JSON.parse(args[args.indexOf("--settings") + 1]);
		assert.match(settings.claudeMdExcludes[0], /\/\.claude\/\*\*$/);
		assert.ok(!args.includes("--plugin-dir"));
	});

	test("with-skill loads the plugin and lets file tools read it", () => {
		const args = isolationArgs({ pluginDir: "/tmp/plugin" });
		assert.equal(args[args.indexOf("--plugin-dir") + 1], "/tmp/plugin");
		assert.equal(args[args.indexOf("--add-dir") + 1], "/tmp/plugin");
	});

	test("trials never get a blanket Bash allow", () => {
		const args = trialArgs({ model: "opus" });
		assert.ok(!args.includes("Bash"));
		assert.ok(!args.includes("PowerShell"));
		assert.equal(args[args.indexOf("--permission-prompts") + 1], "none");
	});

	test("the judge gets no tools", () => {
		const args = judgeArgs({ model: "opus", schema: { type: "object" } });
		assert.equal(args[args.indexOf("--tools") + 1], "");
		assert.ok(!args.includes("--plugin-dir"));
	});

	test("child sessions don't inherit the launching session's state", () => {
		const env = childEnv({ PATH: "x", CLAUDECODE: "1", CLAUDE_CODE_SESSION_ID: "s", CLAUDE_EFFORT: "max", AI_AGENT: "a", CLAUDE_CONFIG_DIR: "c" });
		assert.deepEqual(env, { PATH: "x", CLAUDE_CONFIG_DIR: "c", CLAUDE_CODE_DISABLE_AUTO_MEMORY: "1" });
	});
});

describe("task files", () => {
	const base = { id: 1, name: "t", prompt: "Do it", rubric: ["Works"] };

	test("the smoke task is valid", () => {
		const task = loadTask(path.join(HERE, "..", "..", "smoke", "block-catalog.json"));
		assert.deepEqual(task.auto_checks, ["luau-lsp", "selene", "stylua"]);
	});

	test("rejects paths that leave the project", () => {
		assert.throws(() => validateTask({ ...base, checks: [{ type: "file_exists", path: "../outside.luau" }] }), /\.\./);
		assert.throws(() => validateTask({ ...base, checks: [{ type: "file_exists", path: "C:/Windows/x" }] }), /relative/);
		assert.throws(() => validateTask({ ...base, setup_files: [{ from: "/etc/passwd", to: "src/x" }] }), /relative/);
	});

	test("rejects shell strings, bad regexes, and missing rubrics", () => {
		assert.throws(() => validateTask({ ...base, checks: [{ type: "command", run: "rm -rf /" }] }), /array/);
		assert.throws(() => validateTask({ ...base, checks: [{ type: "file_matches", path: "a", pattern: "(" }] }));
		assert.throws(() => validateTask({ ...base, rubric: [] }), /rubric/);
		assert.throws(() => validateTask({ ...base, name: "Bad Name" }), /name/);
	});
});

describe("task checks", () => {
	const project = path.join(tmp, "project");
	mkdirSync(path.join(project, "src"), { recursive: true });
	writeFileSync(path.join(project, "src", "A.luau"), "return table.freeze({ Window = 1, Wood = 2 })\n");

	test("evaluates each check type", () => {
		const results = runTaskChecks({
			projectDir: project,
			checks: [
				{ type: "file_exists", path: "src/A.luau" },
				{ type: "file_absent", path: "src/B.luau" },
				{ type: "file_matches", path: "src/A.luau", pattern: "table\\.freeze" },
				{ type: "file_not_matches", path: "src/A.luau", pattern: "print" },
				{ type: "any_file_matches", dir: "src", ext: ".luau", pattern: "Wood" },
				{ type: "file_exists", path: "src/Missing.luau" },
			],
		});
		assert.deepEqual(
			results.map((r) => r.passed),
			[true, true, true, true, true, false],
		);
	});

	test("a check that escapes the project fails instead of reading outside it", () => {
		const [res] = runTaskChecks({ projectDir: project, checks: [{ type: "file_exists", path: "../../x" }] });
		assert.equal(res.passed, false);
		assert.match(res.evidence, /escapes/);
	});

	test("grading summary matches skill-creator's schema", () => {
		const g = buildGrading([{ text: "a", passed: true, evidence: "" }, { text: "b", passed: false, evidence: "" }], {});
		assert.deepEqual(g.summary, { passed: 1, failed: 1, total: 2, pass_rate: 0.5 });
	});

	test("evidence drops the trial's absolute path and log noise", () => {
		const out = trimEvidence("[INFO] loading\nc:\\work\\proj\\src\\A.luau(1,1): TypeError", "C:\\work\\proj");
		assert.equal(out, "\\src\\A.luau(1,1): TypeError");
	});
});

describe("paths", () => {
	test("resolveInside refuses to escape", () => {
		assert.throws(() => resolveInside(tmp, "../x"), /escapes/);
		assert.equal(resolveInside(tmp, "a/b"), path.join(tmp, "a", "b"));
	});

	test("finds a CLAUDE.md above a results folder", () => {
		const parent = path.join(tmp, "parent");
		mkdirSync(path.join(parent, "child"), { recursive: true });
		writeFileSync(path.join(parent, "CLAUDE.md"), "# x");
		assert.ok(ancestorMemoryFiles(path.join(parent, "child")).includes(path.join(parent, "CLAUDE.md")));
	});

	test("evidence redaction covers drive-letter case and JSON escaping", () => {
		const out = redactPaths({ a: "C:\\w\\x\\y", b: "c:\\w\\x", c: "C:/w/x/z" }, ["C:\\w\\x"]);
		assert.deepEqual(out, { a: "<work>\\y", b: "<work>", c: "<work>/z" });
	});

	test("export redacts the results folder and home folder", () => {
		const home = os.homedir();
		const text = JSON.stringify({ a: path.join(tmp, "eval-1"), b: path.join(home, "x") });
		const out = redact(text, tmp);
		assert.ok(!out.includes(home.replace(/\\/g, "\\\\")));
		assert.ok(out.includes("<results>"));
	});
});

describe("trial status", () => {
	const ok = { ok: true, problems: [] };
	test("orders spawn errors, timeouts, contamination, and failures", () => {
		assert.equal(trialStatus({ outcome: { spawnError: "x" }, result: null, isolation: ok }), "failed");
		assert.equal(trialStatus({ outcome: { timedOut: true }, result: null, isolation: ok }), "timeout");
		assert.equal(trialStatus({ outcome: { exitCode: 0 }, result: {}, isolation: { ok: false } }), "contaminated");
		assert.equal(trialStatus({ outcome: { exitCode: 1 }, result: {}, isolation: ok }), "failed");
		assert.equal(trialStatus({ outcome: { exitCode: 0 }, result: { is_error: false }, isolation: ok }), "ok");
	});
});

describe("blind judge", () => {
	test("labels follow the coin flip", () => {
		const w = { id: "with" };
		const b = { id: "base" };
		assert.deepEqual(assignLabels(w, b, 0), { A: w, B: b });
		assert.deepEqual(assignLabels(w, b, 1), { A: b, B: w });
	});

	test("skill names are scrubbed from what the judge sees", () => {
		assert.equal(scrub("-- per roblox-dev:vide and roblox-dev:code-comments"), "-- per <skill> and <skill>");
	});

	test("template placeholders are filled", () => {
		assert.equal(fillTemplate("{{A}} and {{B}} and {{C}}", { A: "1", B: "$&" }), "1 and $& and {{C}}");
	});

	test("summaries count wins per setup", () => {
		const r = (winner, w, b) => ({ status: "ok", winner_config: winner, scores_by_config: { with_skill: w, without_skill: b }, tokens: 100, wall_seconds: 10 });
		const s = summarizeJudgements({ "eval-1": [r("with_skill", 8, 6), r("TIE", 7, 7), { status: "timeout", pair: 3 }] });
		assert.deepEqual(s.evals["eval-1"].wins, { with_skill: 1, without_skill: 0, TIE: 1 });
		assert.deepEqual(s.evals["eval-1"].mean_score, { with_skill: 7.5, without_skill: 6.5 });
		assert.equal(s.totals.judged, 2);
		assert.equal(s.totals.pairs, 3);
	});
});
