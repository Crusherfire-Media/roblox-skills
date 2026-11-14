import { spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";

export function writeJson(file, value) {
	mkdirSync(path.dirname(file), { recursive: true });
	writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

export function readJson(file) {
	return JSON.parse(readFileSync(file, "utf8"));
}

// Resolves rel inside root and refuses anything that lands outside it.
export function resolveInside(root, rel) {
	const base = path.resolve(root);
	const full = path.resolve(base, rel);
	const relative = path.relative(base, full);
	if (relative.startsWith("..") || path.isAbsolute(relative)) {
		throw new Error(`path escapes ${base}: ${rel}`);
	}
	return full;
}

export function isInside(parent, child) {
	const relative = path.relative(path.resolve(parent), path.resolve(child));
	return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

// Claude Code loads CLAUDE.md files from every folder above the working directory.
// Trials run below dir, so any such file would reach both setups. The home folder's
// .claude/CLAUDE.md is user memory, which isolationArgs already excludes.
export function ancestorMemoryFiles(dir) {
	const home = path.resolve(os.homedir());
	const found = [];
	let current = path.resolve(dir);
	for (;;) {
		const candidates = ["CLAUDE.md", "CLAUDE.local.md"];
		if (current !== home) candidates.push(path.join(".claude", "CLAUDE.md"));
		for (const name of candidates) {
			const file = path.join(current, name);
			if (existsSync(file)) found.push(file);
		}
		const parent = path.dirname(current);
		if (parent === current) break;
		current = parent;
	}
	return found;
}

export function git(cwd, args) {
	const res = spawnSync("git", args, { cwd, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
	if (res.error) throw new Error(`git ${args[0]} failed: ${res.error.message}`);
	return res;
}

export function copySandbox(sandboxDir, dest) {
	cpSync(sandboxDir, dest, { recursive: true });
}

export function applySetupFiles(task, projectDir) {
	if (task.setup_files.length === 0) return;
	const taskDir = path.dirname(task.file);
	for (const f of task.setup_files) {
		const from = resolveInside(taskDir, f.from);
		const to = resolveInside(projectDir, f.to);
		mkdirSync(path.dirname(to), { recursive: true });
		cpSync(from, to, { recursive: true });
	}
	// Setup files are part of the starting point, so the diff shows only the trial's work.
	git(projectDir, ["add", "-A"]);
	const res = git(projectDir, ["-c", "user.name=eval-harness", "-c", "user.email=eval-harness@localhost", "commit", "-q", "-m", "Task setup files"]);
	if (res.status !== 0) throw new Error(`committing setup files failed: ${res.stderr}`);
}

export function headCommit(projectDir) {
	const res = git(projectDir, ["rev-parse", "HEAD"]);
	if (res.status !== 0) throw new Error(`not a git repository: ${projectDir}`);
	return res.stdout.trim();
}

// Files the trial added or changed since base (ignored files such as sourcemap.json
// and packages are left out by the sandbox's .gitignore).
export function changedFiles(projectDir, base) {
	git(projectDir, ["add", "-A"]);
	const res = git(projectDir, ["diff", "--cached", "--name-status", "--no-renames", base]);
	if (res.status !== 0) throw new Error(`git diff failed: ${res.stderr}`);
	const changed = [];
	const deleted = [];
	for (const line of res.stdout.split(/\r?\n/)) {
		if (!line.trim()) continue;
		const [status, file] = line.split("\t");
		(status === "D" ? deleted : changed).push(file);
	}
	return { changed, deleted };
}

export function diffAgainst(projectDir, base) {
	git(projectDir, ["add", "-A"]);
	const res = git(projectDir, ["diff", "--cached", "--no-renames", base]);
	if (res.status !== 0) throw new Error(`git diff failed: ${res.stderr}`);
	return res.stdout;
}

export function saveChangedFiles(projectDir, files, destDir) {
	for (const file of files) {
		const from = resolveInside(projectDir, file);
		if (!existsSync(from)) continue;
		const to = resolveInside(destDir, file);
		mkdirSync(path.dirname(to), { recursive: true });
		cpSync(from, to);
	}
}
