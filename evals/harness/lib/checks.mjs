import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";

import { resolveInside } from "./workspace.mjs";

const LUAU = /\.luau?$/i;
const EVIDENCE_LIMIT = 1500;

function run(cmd, args, cwd, timeoutMs = 120_000) {
	const res = spawnSync(cmd, args, { cwd, encoding: "utf8", timeout: timeoutMs, maxBuffer: 16 * 1024 * 1024, windowsHide: true });
	return {
		status: res.status,
		error: res.error ? res.error.message : null,
		output: `${res.stdout ?? ""}${res.stderr ?? ""}`,
	};
}

// Shortens tool output for the evidence field and drops the trial's absolute path.
export function trimEvidence(text, projectDir) {
	let out = String(text ?? "");
	if (projectDir) {
		const variants = new Set([projectDir, projectDir.replace(/\\/g, "/"), projectDir.toLowerCase(), projectDir.replace(/\\/g, "/").toLowerCase()]);
		for (const v of variants) out = out.split(v).join("");
		// luau-lsp prints the drive letter in lower case.
		const lowerDrive = projectDir.replace(/^([A-Z]):/, (_, d) => `${d.toLowerCase()}:`);
		out = out.split(lowerDrive).join("");
	}
	out = out
		.split(/\r?\n/)
		.filter((l) => !/^\[(INFO|WARN)\]/.test(l))
		.join("\n")
		.trim();
	return out.length > EVIDENCE_LIMIT ? `${out.slice(0, EVIDENCE_LIMIT)}\n... (truncated)` : out;
}

function toolExpectation(text, res, projectDir) {
	if (res.error) return { text, passed: false, evidence: `tool failed to run: ${res.error}` };
	return { text, passed: res.status === 0, evidence: trimEvidence(res.output, projectDir) || `exit ${res.status}` };
}

export function runAutoChecks({ projectDir, changedLuau, autoChecks, definitionsFile = "globalTypes.d.luau" }) {
	const expectations = [];
	const texts = {
		"luau-lsp": "luau-lsp analyze reports no errors in the changed Luau files",
		selene: "selene reports no errors in the changed Luau files",
		stylua: "stylua --check passes on the changed Luau files",
	};
	if (changedLuau.length === 0) {
		for (const name of autoChecks) expectations.push({ text: texts[name], passed: false, evidence: "no Luau files changed" });
		return expectations;
	}
	if (autoChecks.includes("luau-lsp")) {
		const sourcemap = run("rojo", ["sourcemap", "default.project.json", "-o", "sourcemap.json", "--include-non-scripts"], projectDir);
		if (sourcemap.status !== 0) {
			expectations.push({ text: texts["luau-lsp"], passed: false, evidence: `rojo sourcemap failed: ${trimEvidence(sourcemap.error ?? sourcemap.output, projectDir)}` });
		} else {
			const res = run(
				"luau-lsp",
				[
					"analyze",
					"--platform=roblox",
					`--definitions:@roblox=${definitionsFile}`,
					"--sourcemap=sourcemap.json",
					"--ignore=**/roblox_packages/**",
					...changedLuau,
				],
				projectDir,
			);
			expectations.push(toolExpectation(texts["luau-lsp"], res, projectDir));
		}
	}
	if (autoChecks.includes("selene")) {
		expectations.push(toolExpectation(texts.selene, run("selene", changedLuau, projectDir), projectDir));
	}
	if (autoChecks.includes("stylua")) {
		expectations.push(toolExpectation(texts.stylua, run("stylua", ["--check", ...changedLuau], projectDir), projectDir));
	}
	return expectations;
}

function listFiles(dir, out = []) {
	for (const entry of readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			if (entry.name === ".git" || entry.name === "roblox_packages" || entry.name.startsWith(".pesde")) continue;
			listFiles(full, out);
		} else {
			out.push(full);
		}
	}
	return out;
}

function describe(check) {
	switch (check.type) {
		case "file_exists":
			return `${check.path} exists`;
		case "file_absent":
			return `${check.path} does not exist`;
		case "file_matches":
			return `${check.path} matches /${check.pattern}/`;
		case "file_not_matches":
			return `${check.path} does not match /${check.pattern}/`;
		case "any_file_matches":
			return `a file under ${check.dir ?? "."} matches /${check.pattern}/`;
		case "command":
			return `\`${check.run.join(" ")}\` exits ${check.expect_exit ?? 0}`;
		default:
			return check.type;
	}
}

export function runTaskChecks({ projectDir, checks }) {
	return checks.map((check) => {
		const text = check.text ?? describe(check);
		try {
			if (check.type === "command") {
				const res = run(check.run[0], check.run.slice(1), projectDir, (check.timeout_seconds ?? 120) * 1000);
				if (res.error) return { text, passed: false, evidence: `command failed to run: ${res.error}` };
				return { text, passed: res.status === (check.expect_exit ?? 0), evidence: trimEvidence(res.output, projectDir) || `exit ${res.status}` };
			}
			if (check.type === "any_file_matches") {
				const dir = resolveInside(projectDir, check.dir ?? ".");
				const re = new RegExp(check.pattern, check.flags ?? "m");
				const ext = check.ext ?? null;
				const hits = existsSync(dir)
					? listFiles(dir).filter((f) => (!ext || f.endsWith(ext)) && re.test(readFileSync(f, "utf8")))
					: [];
				return { text, passed: hits.length > 0, evidence: hits.length ? `matched in ${hits.map((h) => path.relative(projectDir, h).replace(/\\/g, "/")).join(", ")}` : "no file matched" };
			}
			const file = resolveInside(projectDir, check.path);
			const exists = existsSync(file) && statSync(file).isFile();
			if (check.type === "file_exists") return { text, passed: exists, evidence: exists ? "found" : "missing" };
			if (check.type === "file_absent") return { text, passed: !exists, evidence: exists ? "still present" : "absent" };
			if (!exists) return { text, passed: false, evidence: "file missing" };
			const re = new RegExp(check.pattern, check.flags ?? "m");
			const match = re.exec(readFileSync(file, "utf8"));
			if (check.type === "file_matches") return { text, passed: !!match, evidence: match ? `matched: ${match[0].slice(0, 200)}` : "no match" };
			return { text, passed: !match, evidence: match ? `matched: ${match[0].slice(0, 200)}` : "no match" };
		} catch (err) {
			return { text, passed: false, evidence: `check failed: ${err.message}` };
		}
	});
}

export function buildGrading(expectations, executionMetrics, notes = {}) {
	const passed = expectations.filter((e) => e.passed).length;
	const total = expectations.length;
	return {
		expectations,
		summary: { passed, failed: total - passed, total, pass_rate: total ? Math.round((passed / total) * 10000) / 10000 : 0 },
		execution_metrics: executionMetrics,
		user_notes_summary: { uncertainties: [], needs_review: notes.needs_review ?? [], workarounds: [] },
	};
}

export { LUAU };
