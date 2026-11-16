#!/usr/bin/env python3
"""Description trigger tests for a plugin skill, under the harness isolation.

Reuses skill-creator's run_eval.run_eval (trigger rates per query) and
run_loop.run_loop (train/test split plus description rewrites), and swaps in two
functions:

- run_single_query: skill-creator's version writes a temporary .claude/commands
  file and runs `claude -p` with this machine's full configuration, then reads its
  output with select(), which does not work on pipes on Windows. A user-scope
  plugin with the same skill descriptions (or hooks that suggest skills) makes the
  model pick that plugin's skill, which counts as "not triggered". This version
  copies the plugin under test into a temp folder with the candidate description,
  loads it with --plugin-dir under the same isolation flags as the trials, checks
  the init event, and counts a trigger when the session calls the Skill tool for
  <plugin>:<skill> (or reads that skill's SKILL.md) before it edits a file.
- improve_description._call_claude: the description rewriter runs isolated too.

Usage (from anywhere; Python 3.10+):

  python evals/harness/trigger_eval.py eval --eval-set <queries.json> \
      --plugin-dir plugins/roblox-dev --skill vide [--sandbox <dir>] \
      [--runs-per-query 3] [--num-workers 5] [--timeout 120] [--model opus] [--out <file>]

  python evals/harness/trigger_eval.py loop --eval-set <queries.json> \
      --plugin-dir plugins/roblox-dev --skill vide [--sandbox <dir>] \
      [--max-iterations 5] [--holdout 0.4] [--model opus] [--out <file>]

The eval set is skill-creator's format: [{"query": "...", "should_trigger": true}, ...].
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
TRIAL_TOOLS = "Task,Bash,PowerShell,Edit,Write,Read,Glob,Grep,Skill,ToolSearch,WebFetch,WebSearch"
EDIT_TOOLS = {"Edit", "Write", "NotebookEdit"}
MAX_TOOL_CALLS = 8


def skill_creator_dir() -> Path:
    if os.environ.get("SKILL_CREATOR_DIR"):
        return Path(os.environ["SKILL_CREATOR_DIR"]).resolve()
    config = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
    registry = config / "plugins" / "installed_plugins.json"
    if registry.exists():
        data = json.loads(registry.read_text(encoding="utf-8"))
        for key, installs in data.get("plugins", {}).items():
            if not key.startswith("skill-creator@"):
                continue
            for install in installs:
                candidate = Path(install["installPath"]) / "skills" / "skill-creator"
                if (candidate / "scripts" / "run_eval.py").exists():
                    return candidate
    raise SystemExit("skill-creator plugin not found; install it or set SKILL_CREATOR_DIR")


def child_env() -> dict[str, str]:
    """Environment for claude without the launching session's state (see lib/claude.mjs)."""
    env = {}
    for key, value in os.environ.items():
        if key == "CLAUDE_CONFIG_DIR":
            env[key] = value
        elif key.upper().startswith("CLAUDE") or key == "AI_AGENT":
            continue
        else:
            env[key] = value
    env["CLAUDE_CODE_DISABLE_AUTO_MEMORY"] = "1"
    return env


def isolation_args(plugin_dir: str | None) -> list[str]:
    """Same flags as isolationArgs in lib/isolation.mjs."""
    home = str(Path.home()).replace("\\", "/")
    settings = {"claudeMdExcludes": [f"{home}/.claude/**"]}
    args = ["--restricted", "--setting-sources", "project,local", "--strict-mcp-config", "--settings", json.dumps(settings)]
    if plugin_dir:
        args += ["--plugin-dir", plugin_dir, "--add-dir", plugin_dir]
    return args


def replace_description(skill_md: str, description: str) -> str:
    """Returns SKILL.md text with the frontmatter description replaced."""
    lines = skill_md.split("\n")
    if not lines or lines[0].strip() != "---":
        raise ValueError("SKILL.md has no frontmatter")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise ValueError("SKILL.md frontmatter is not closed")
    out = [lines[0]]
    i = 1
    replaced = False
    while i < end:
        line = lines[i]
        if line.startswith("description:"):
            i += 1
            while i < end and (lines[i].startswith("  ") or lines[i].startswith("\t") or not lines[i].strip()):
                i += 1
            out.append("description: |")
            out.extend(f"  {part}" for part in description.split("\n"))
            replaced = True
            continue
        out.append(line)
        i += 1
    if not replaced:
        raise ValueError("SKILL.md frontmatter has no description")
    return "\n".join(out + lines[end:])


def check_init(init: dict, plugin_name: str) -> list[str]:
    """A short form of checkIsolation in lib/isolation.mjs for the with-skill setup."""
    problems = []
    for p in init.get("plugins", []):
        source = str(p.get("source", ""))
        if source.endswith("@builtin"):
            continue
        if source != f"{plugin_name}@inline":
            problems.append(f"unexpected plugin {source or p.get('name')}")
    for s in init.get("skills", []):
        if ":" in s and not s.startswith(f"{plugin_name}:"):
            problems.append(f"unexpected skill {s}")
    for m in init.get("mcp_servers", []):
        problems.append(f"unexpected MCP server {m.get('name')}")
    return problems


def _reader(stream, q: "queue.Queue[str | None]") -> None:
    for raw in iter(stream.readline, b""):
        q.put(raw.decode("utf-8", errors="replace"))
    q.put(None)


def isolated_run_single_query(query, skill_name, skill_description, timeout, project_root, model=None) -> bool:
    plugin_dir = Path(os.environ["TRIGGER_EVAL_PLUGIN_DIR"])
    plugin_name = os.environ["TRIGGER_EVAL_PLUGIN_NAME"]
    sandbox = os.environ.get("TRIGGER_EVAL_SANDBOX") or None
    work = Path(tempfile.mkdtemp(prefix="trigger-", dir=os.environ.get("TRIGGER_EVAL_WORK") or None))
    try:
        plugin_copy = work / "plugin" / plugin_dir.name
        shutil.copytree(plugin_dir, plugin_copy)
        skill_md = plugin_copy / "skills" / skill_name / "SKILL.md"
        skill_md.write_text(replace_description(skill_md.read_text(encoding="utf-8"), skill_description), encoding="utf-8")
        project = work / "project"
        if sandbox:
            shutil.copytree(sandbox, project)
        else:
            project.mkdir()

        cmd = [
            "claude", "-p", "--output-format", "stream-json", "--verbose", "--no-session-persistence",
            "--tools", TRIAL_TOOLS, "--permission-mode", "acceptEdits", "--permission-prompts", "none",
        ]
        if model:
            cmd += ["--model", model]
        cmd += isolation_args(str(plugin_copy))
        target = f"{plugin_name}:{skill_name}"
        skill_path_re = re.compile(rf"skills[\\/]+{re.escape(skill_name)}[\\/]+SKILL\.md$", re.IGNORECASE)

        proc = subprocess.Popen(cmd, cwd=project, env=child_env(), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        q: "queue.Queue[str | None]" = queue.Queue()
        threading.Thread(target=_reader, args=(proc.stdout, q), daemon=True).start()
        proc.stdin.write(query.encode("utf-8"))
        proc.stdin.close()
        deadline = time.time() + timeout
        tool_calls = 0
        try:
            while time.time() < deadline:
                try:
                    line = q.get(timeout=1.0)
                except queue.Empty:
                    continue
                if line is None:
                    return False
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if event.get("type") == "system" and event.get("subtype") == "init":
                    problems = check_init(event, plugin_name)
                    if problems:
                        raise RuntimeError("contaminated session: " + "; ".join(problems))
                elif event.get("type") == "assistant":
                    for block in event.get("message", {}).get("content", []):
                        if block.get("type") != "tool_use":
                            continue
                        tool_calls += 1
                        name = block.get("name")
                        args = block.get("input", {})
                        if name == "Skill" and args.get("skill") == target:
                            return True
                        if name == "Read" and skill_path_re.search(str(args.get("file_path", ""))):
                            return True
                        if name in EDIT_TOOLS or tool_calls >= MAX_TOOL_CALLS:
                            return False
                elif event.get("type") == "result":
                    return False
            return False
        finally:
            if proc.poll() is None:
                if os.name == "nt":
                    subprocess.run(["taskkill", "/pid", str(proc.pid), "/T", "/F"], capture_output=True)
                else:
                    proc.kill()
                proc.wait()
    finally:
        shutil.rmtree(work, ignore_errors=True)


def isolated_call_claude(prompt: str, model: str | None, timeout: int = 300) -> str:
    cmd = ["claude", "-p", "--output-format", "text", "--tools", "", "--no-session-persistence"]
    if model:
        cmd += ["--model", model]
    cmd += isolation_args(None)
    with tempfile.TemporaryDirectory(prefix="improve-") as cwd:
        result = subprocess.run(cmd, input=prompt, capture_output=True, text=True, encoding="utf-8", env=child_env(), cwd=cwd, timeout=timeout)
    if result.returncode != 0:
        raise RuntimeError(f"claude -p exited {result.returncode}\nstderr: {result.stderr}")
    return result.stdout


def main() -> None:
    # skill-creator reads files with the platform's default encoding; UTF-8 mode
    # keeps SKILL.md and eval sets from being read as cp1252 on Windows.
    if not sys.flags.utf8_mode:
        env = {**os.environ, "PYTHONUTF8": "1"}
        sys.exit(subprocess.run([sys.executable, "-X", "utf8", *sys.argv], env=env).returncode)

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mode", choices=["eval", "loop"])
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--plugin-dir", required=True)
    parser.add_argument("--skill", required=True, help="skill folder name under <plugin>/skills")
    parser.add_argument("--sandbox", default=None, help="project folder to copy into each query's working folder")
    parser.add_argument("--description", default=None, help="description to test instead of the SKILL.md one")
    parser.add_argument("--runs-per-query", type=int, default=3)
    parser.add_argument("--trigger-threshold", type=float, default=0.5)
    parser.add_argument("--num-workers", type=int, default=5)
    parser.add_argument("--timeout", type=int, default=120, help="seconds per query")
    parser.add_argument("--max-iterations", type=int, default=5)
    parser.add_argument("--holdout", type=float, default=0.4)
    parser.add_argument("--model", default="opus")
    parser.add_argument("--out", default=None, help="write the JSON result here")
    args = parser.parse_args()

    plugin_dir = Path(args.plugin_dir).resolve()
    manifest = json.loads((plugin_dir / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
    skill_dir = plugin_dir / "skills" / args.skill
    if not (skill_dir / "SKILL.md").exists():
        raise SystemExit(f"no SKILL.md at {skill_dir}")
    # The query runner finds the skill folder by its frontmatter name.
    if not re.search(rf"^name:\s*['\"]?{re.escape(args.skill)}['\"]?\s*$", (skill_dir / "SKILL.md").read_text(encoding="utf-8"), re.MULTILINE):
        raise SystemExit(f"the name in {skill_dir / 'SKILL.md'} must match the folder name {args.skill}")
    eval_set = json.loads(Path(args.eval_set).read_text(encoding="utf-8"))
    if not isinstance(eval_set, list) or not all(isinstance(e, dict) and isinstance(e.get("query"), str) and isinstance(e.get("should_trigger"), bool) for e in eval_set):
        raise SystemExit("eval set must be a list of {query: string, should_trigger: boolean}")

    os.environ["TRIGGER_EVAL_PLUGIN_DIR"] = str(plugin_dir)
    os.environ["TRIGGER_EVAL_PLUGIN_NAME"] = manifest["name"]
    if args.sandbox:
        os.environ["TRIGGER_EVAL_SANDBOX"] = str(Path(args.sandbox).resolve())

    sys.path.insert(0, str(skill_creator_dir()))
    import scripts.improve_description as improve_mod  # noqa: E402
    import scripts.run_eval as run_eval_mod  # noqa: E402
    from scripts.utils import parse_skill_md  # noqa: E402

    run_eval_mod.run_single_query = isolated_run_single_query
    improve_mod._call_claude = isolated_call_claude

    if args.mode == "eval":
        name, description, _ = parse_skill_md(skill_dir)
        output = run_eval_mod.run_eval(
            eval_set=eval_set,
            skill_name=name,
            description=args.description or description,
            num_workers=args.num_workers,
            timeout=args.timeout,
            project_root=Path.cwd(),
            runs_per_query=args.runs_per_query,
            trigger_threshold=args.trigger_threshold,
            model=args.model,
        )
    else:
        import scripts.run_loop as run_loop_mod  # noqa: E402

        output = run_loop_mod.run_loop(
            eval_set=eval_set,
            skill_path=skill_dir,
            description_override=args.description,
            num_workers=args.num_workers,
            timeout=args.timeout,
            max_iterations=args.max_iterations,
            runs_per_query=args.runs_per_query,
            trigger_threshold=args.trigger_threshold,
            holdout=args.holdout,
            model=args.model,
            verbose=True,
        )
    text = json.dumps(output, indent=2)
    if args.out:
        Path(args.out).write_text(text + "\n", encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
