import { readFileSync } from "node:fs";
import path from "node:path";

export const AUTO_CHECKS = ["luau-lsp", "selene", "stylua"];
const CHECK_TYPES = ["file_exists", "file_absent", "file_matches", "file_not_matches", "any_file_matches", "command"];

// Paths in a task file are relative to the project (or, for setup files, to the
// task file's folder). Rejecting absolute paths and ".." keeps a task from reading
// or writing outside those folders.
export function assertRelativePath(p, label) {
	if (typeof p !== "string" || p.length === 0 || p.length > 300) throw new Error(`${label} must be a non-empty path`);
	if (path.isAbsolute(p) || /^[a-zA-Z]:/.test(p)) throw new Error(`${label} must be relative: ${p}`);
	if (p.split(/[\\/]/).includes("..")) throw new Error(`${label} must not contain "..": ${p}`);
}

function assertString(value, label, max) {
	if (typeof value !== "string" || value.trim().length === 0) throw new Error(`${label} must be a non-empty string`);
	if (value.length > max) throw new Error(`${label} is longer than ${max} characters`);
}

function validateCheck(check, i) {
	const label = `checks[${i}]`;
	if (!check || typeof check !== "object") throw new Error(`${label} must be an object`);
	if (!CHECK_TYPES.includes(check.type)) throw new Error(`${label}.type must be one of ${CHECK_TYPES.join(", ")}`);
	if (check.text !== undefined) assertString(check.text, `${label}.text`, 300);
	if (check.type === "command") {
		if (!Array.isArray(check.run) || check.run.length === 0 || !check.run.every((a) => typeof a === "string")) {
			throw new Error(`${label}.run must be a non-empty array of strings (no shell)`);
		}
		if (check.expect_exit !== undefined && !Number.isInteger(check.expect_exit)) {
			throw new Error(`${label}.expect_exit must be an integer`);
		}
		return;
	}
	if (check.type === "any_file_matches") {
		assertRelativePath(check.dir ?? ".", `${label}.dir`);
	} else {
		assertRelativePath(check.path, `${label}.path`);
	}
	if (["file_matches", "file_not_matches", "any_file_matches"].includes(check.type)) {
		assertString(check.pattern, `${label}.pattern`, 500);
		new RegExp(check.pattern, check.flags ?? "m");
	}
}

export function validateTask(task) {
	if (!task || typeof task !== "object") throw new Error("task must be a JSON object");
	if (!Number.isInteger(task.id) || task.id < 0) throw new Error("id must be a non-negative integer");
	if (typeof task.name !== "string" || !/^[a-z0-9][a-z0-9-]{0,63}$/.test(task.name)) {
		throw new Error("name must be lowercase letters, digits, and dashes");
	}
	assertString(task.prompt, "prompt", 20000);
	if (task.skill !== undefined && (typeof task.skill !== "string" || !/^[a-z0-9-]+$/.test(task.skill))) {
		throw new Error("skill must be a skill name such as vide");
	}
	if (!Array.isArray(task.rubric) || task.rubric.length === 0 || task.rubric.length > 12) {
		throw new Error("rubric must list 1 to 12 criteria");
	}
	task.rubric.forEach((c, i) => assertString(c, `rubric[${i}]`, 500));
	const autoChecks = task.auto_checks ?? AUTO_CHECKS;
	if (!Array.isArray(autoChecks) || !autoChecks.every((c) => AUTO_CHECKS.includes(c))) {
		throw new Error(`auto_checks must be a subset of ${AUTO_CHECKS.join(", ")}`);
	}
	const checks = task.checks ?? [];
	if (!Array.isArray(checks)) throw new Error("checks must be an array");
	checks.forEach(validateCheck);
	const setupFiles = task.setup_files ?? [];
	if (!Array.isArray(setupFiles)) throw new Error("setup_files must be an array");
	setupFiles.forEach((f, i) => {
		assertRelativePath(f?.from, `setup_files[${i}].from`);
		assertRelativePath(f?.to, `setup_files[${i}].to`);
	});
	const timeout = task.timeout_minutes ?? 20;
	if (typeof timeout !== "number" || timeout <= 0 || timeout > 120) {
		throw new Error("timeout_minutes must be between 0 and 120");
	}
	return { ...task, auto_checks: autoChecks, checks, setup_files: setupFiles, timeout_minutes: timeout };
}

export function loadTask(file) {
	let raw;
	try {
		raw = JSON.parse(readFileSync(file, "utf8"));
	} catch (err) {
		throw new Error(`cannot read task file ${file}: ${err.message}`);
	}
	try {
		return { ...validateTask(raw), file: path.resolve(file) };
	} catch (err) {
		throw new Error(`invalid task file ${file}: ${err.message}`);
	}
}
