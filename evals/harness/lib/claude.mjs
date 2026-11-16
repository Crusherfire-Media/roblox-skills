import { spawn, spawnSync } from "node:child_process";
import { createWriteStream } from "node:fs";

import { isolationArgs } from "./isolation.mjs";

// Tools a trial gets. --restricted removes the command tools unless they are named.
export const TRIAL_TOOLS = "Task,Bash,PowerShell,Edit,Write,Read,Glob,Grep,Skill,ToolSearch,WebFetch,WebSearch";

// Calls a trial may make without a permission prompt. Edits inside the project are
// allowed by acceptEdits and read-only commands inside it need no prompt; anything
// else that would prompt is denied (--permission-prompts none).
export const TRIAL_ALLOWED_TOOLS = [
	"WebFetch",
	"WebSearch",
	"Bash(rojo sourcemap *)",
	"Bash(luau-lsp analyze *)",
	"Bash(selene *)",
	"Bash(stylua *)",
	"Bash(git status*)",
	"Bash(git diff*)",
	"PowerShell(rojo sourcemap *)",
	"PowerShell(luau-lsp analyze *)",
	"PowerShell(selene *)",
	"PowerShell(stylua *)",
	"PowerShell(git status*)",
	"PowerShell(git diff*)",
];

// A Claude Code session that launches the harness passes its own session state
// (CLAUDECODE, CLAUDE_CODE_SESSION_ID, CLAUDE_EFFORT, messaging sockets, ...) to its
// children. Trials start without any of it.
export function childEnv(base = process.env) {
	const env = {};
	for (const [key, value] of Object.entries(base)) {
		if (key === "CLAUDE_CONFIG_DIR") env[key] = value;
		else if (/^CLAUDE/i.test(key) || key === "AI_AGENT") continue;
		else env[key] = value;
	}
	env.CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
	return env;
}

export function trialArgs({ model, pluginDir = null, effort = null, maxBudgetUsd = null, extraDisabledPlugins = [] }) {
	const args = [
		"-p",
		"--model",
		model,
		"--output-format",
		"stream-json",
		"--verbose",
		"--include-hook-events",
		// Sessions are saved: the plugin's skill-gate and verify-gate read the session
		// transcript to see loaded skills and edited files, and without it they pass silently.
		"--tools",
		TRIAL_TOOLS,
		"--permission-mode",
		"acceptEdits",
		"--permission-prompts",
		"none",
		"--allowedTools",
		...TRIAL_ALLOWED_TOOLS,
	];
	if (effort) args.push("--effort", effort);
	if (maxBudgetUsd) args.push("--max-budget-usd", String(maxBudgetUsd));
	args.push(...isolationArgs({ pluginDir, extraDisabledPlugins }));
	return args;
}

// The judge reads both outputs from its prompt and has no tools, so it can't look
// around the disk for the A/B mapping.
export function judgeArgs({ model, schema, effort = null, extraDisabledPlugins = [] }) {
	const args = [
		"-p",
		"--model",
		model,
		"--output-format",
		"stream-json",
		"--verbose",
		"--include-hook-events",
		"--no-session-persistence",
		"--tools",
		"",
		"--json-schema",
		JSON.stringify(schema),
	];
	if (effort) args.push("--effort", effort);
	args.push(...isolationArgs({ extraDisabledPlugins }));
	return args;
}

function killTree(child) {
	if (child.exitCode !== null) return;
	if (process.platform === "win32") {
		spawnSync("taskkill", ["/pid", String(child.pid), "/T", "/F"], { stdio: "ignore" });
	} else {
		child.kill("SIGKILL");
	}
}

// Runs `claude` with the prompt on stdin (long prompts would overflow the Windows
// command line), streams stdout to transcriptPath, and resolves with the outcome.
// Never rejects: a spawn error or timeout is part of the outcome.
export function runClaude({ args, prompt, cwd, transcriptPath, stderrPath, timeoutMs, claudeBin = "claude" }) {
	return new Promise((resolve) => {
		const started = new Date();
		const out = createWriteStream(transcriptPath);
		const err = createWriteStream(stderrPath);
		let timedOut = false;
		let settled = false;
		const finish = (outcome) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			const ended = new Date();
			let pending = 2;
			const done = () => {
				if (--pending === 0) {
					resolve({
						...outcome,
						timedOut,
						startedAt: started.toISOString(),
						endedAt: ended.toISOString(),
						wallMs: ended - started,
					});
				}
			};
			out.end(done);
			err.end(done);
		};

		let child;
		try {
			child = spawn(claudeBin, args, { cwd, env: childEnv(), stdio: ["pipe", "pipe", "pipe"], windowsHide: true });
		} catch (e) {
			finish({ exitCode: null, spawnError: e.message });
			return;
		}
		const timer = setTimeout(() => {
			timedOut = true;
			killTree(child);
		}, timeoutMs);
		child.stdout.pipe(out, { end: false });
		child.stderr.pipe(err, { end: false });
		child.on("error", (e) => finish({ exitCode: null, spawnError: e.message }));
		child.on("close", (code) => finish({ exitCode: code, spawnError: null }));
		child.stdin.on("error", () => {});
		child.stdin.end(prompt);
	});
}
