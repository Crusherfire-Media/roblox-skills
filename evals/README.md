# Skill evals

A harness that measures whether each `roblox-dev` skill helps. Every trial is a separate headless
Claude Code session (`claude -p`) in its own copy of a small Rojo game project, under one of two
setups:

- **with-skill:** only the `roblox-dev` plugin, loaded from a plugin folder you pass in.
- **baseline:** no Roblox plugin at all.

Results are graded by automatic checks (`luau-lsp analyze`, `selene`, `stylua --check`, plus checks
each task declares) and by a blind Opus judge that compares one with-skill and one baseline output
at a time. Aggregation reuses skill-creator's `aggregate_benchmark.py`, so results show mean,
spread, and the with-skill minus baseline delta.

Nothing in `evals/` ships with the plugin: the plugin is `plugins/roblox-dev/` only.

## Layout

| Path | What it is |
|---|---|
| `harness/build-sandbox.mjs` | Builds the sandbox project into a folder outside the repo |
| `harness/sandbox-template/` | The sandbox's source files: Baseplate place, Vide 0.4.1 through pesde, selene, StyLua |
| `harness/run-trials.mjs` | The runner |
| `harness/judge.mjs`, `harness/judge-prompt.md` | The blind judge and its prompt template |
| `harness/aggregate.mjs` | Benchmark summary (wraps `aggregate_benchmark.py`) |
| `harness/export-results.mjs` | Copies a results folder into the repo with local paths removed |
| `harness/prove-isolation.mjs` | Proves what each setup loads; writes `isolation/` |
| `harness/trigger_eval.py` | Description trigger tests (wraps skill-creator's `run_eval.py` and `run_loop.py`) |
| `harness/fixtures/dummy-plugin/` | A throwaway `roblox-dev` plugin with two dummy skills and two dummy hooks |
| `harness/test/` | `node --test` tests, run by `npm test` |
| `isolation/` | Saved isolation evidence (trimmed init events) |
| `smoke/` | The smoke task and its results |
| `<skill>/` | Per skill, later: `tasks/*.json`, `triggers.json`, `results/<date>/` |

The harness is Node (ES modules, no dependencies), matching the repo's `npm test` setup. The
trigger tests are Python because they import skill-creator's Python modules and swap two of their
functions; `aggregate.mjs` runs `aggregate_benchmark.py` as a subprocess.

## Requirements

- Claude Code, logged in (`claude -p` must work). Trials use `--model opus`.
- Node 22 or later, Python 3.10 or later, and git.
- The Rokit tools pinned in `harness/sandbox-template/rokit.toml` (rojo, pesde, luau-lsp, selene,
  StyLua) installed, so `rokit install` has nothing to fetch.
- The `skill-creator` plugin installed (`claude plugin install skill-creator@claude-plugins-official`).
  The harness finds it in Claude Code's plugin registry; set `SKILL_CREATOR_DIR` to the folder that
  holds its `scripts/` to use another copy.
- Network access to build the sandbox (pesde packages and Roblox type definitions). Trials
  themselves need no network.

## Isolation

A machine can have other plugins enabled at user scope, including a private plugin that carries the
same skills under another name plus hooks that force or suggest skills. A trial that sees any of
that is contaminated. Every trial and judge session gets these flags, and no settings file on the
machine is changed:

| Flag | Effect |
|---|---|
| `--setting-sources project,local` | Drops user settings: user-scope `enabledPlugins`, user hooks, user permissions, and user skills |
| `--strict-mcp-config` | Drops user and claude.ai MCP servers |
| `--settings '{"claudeMdExcludes":["<home>/.claude/**"]}'` | Drops `~/.claude/CLAUDE.md` and `~/.claude/rules/`, which load even without user settings |
| `--restricted` | Confines Read, Grep, Glob, Edit, Write, Bash, and PowerShell to the working folder, so a session can't search the disk and find another plugin's `SKILL.md` files or another trial's output |
| `--plugin-dir <copy> --add-dir <copy>` | with-skill only: loads a per-trial copy of the plugin under test, and lets the file tools read its `references/` files |

The runner also strips the launching session's `CLAUDE*` environment variables, sets
`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`, and refuses to run below a folder that has a `CLAUDE.md`.

Each trial checks its own init event: with-skill passes only when the plugin under test is the one
non-built-in plugin and every namespaced skill comes from it; baseline passes only with no
non-built-in plugin, no namespaced skill, and no hook runs; both fail on any MCP server or any other
Roblox-named skill or agent. A trial that fails this is recorded as `contaminated`, and
`aggregate.mjs` refuses to summarize until it is rerun.

What was verified on 2026-11-13 (Claude Code 2.1.325), with evidence in `isolation/`:

- `with-skill.json`: only `roblox-dev@inline` loads; the fixture skill loads and answers with its
  passphrase; the fixture's `UserPromptSubmit` and `PostToolUse` hooks run.
- `baseline.json`: no plugin, no skill load, no hook runs; the answer is "UNKNOWN".
- `judge.json`: no plugin, no tools except `StructuredOutput` (added by `--json-schema`).
- `control.json`: the same session without the flags loads 12 plugins, 85 namespaced skills (17 named
  Roblox), and 16 MCP servers, and runs 10 hooks; the checker flags all of it. Only counts are saved.

User hooks don't run in trials. Dropping user settings removes every user-level hook, including
shell-command rewriters such as RTK, which would turn `git status` into `rtk git status`. That
breaks `Bash(git *)` allow rules (so a headless run stalls or is denied) and changes the tool output
a trial sees. The evidence shows it: the baseline runs no hooks, the with-skill session runs only the
fixture's two hooks (both outputs carry the fixture's marker), and none of the smoke transcripts
contains an `rtk` command. The control session without the flags runs 10 hooks.

Also verified by experiment: a project or `--settings` `enabledPlugins` entry set to `false`
overrides a user-scope `true` key by key, but leaves the other user plugins and hooks in place, so
the harness doesn't rely on it. `--safe-mode` disables `--plugin-dir` skills too. `--bare` needs an
API key instead of a Claude login.

Rerun the proof after a Claude Code update:

```sh
node evals/harness/prove-isolation.mjs --sandbox <sandbox> --work <scratch>/iso --control
```

## Running evals

Keep every folder below outside the repo, in a place with no `CLAUDE.md` above it (a temp folder
works).

```sh
# 1. Build the sandbox once (about 15 s).
node evals/harness/build-sandbox.mjs <scratch>/sandbox

# 2. Run trials: every task x setup x run, 5 at a time.
node evals/harness/run-trials.mjs --task evals/vide/tasks/a.json,evals/vide/tasks/b.json \
  --sandbox <scratch>/sandbox --out <scratch>/results/vide \
  --plugin-dir "<worktree>/plugins/roblox-dev" --setup both --runs 3 --concurrency 5

# 3. Blind judge: pairs with-skill run-i with baseline run-i.
node evals/harness/judge.mjs --results <scratch>/results/vide

# 4. Aggregate: writes benchmark.json and benchmark.md in the results folder.
node evals/harness/aggregate.mjs --results <scratch>/results/vide --skill-name vide \
  --skill-path "<worktree>/plugins/roblox-dev/skills/vide"

# 5. Save to the repo without local paths (add --transcripts to keep transcripts).
node evals/harness/export-results.mjs --results <scratch>/results/vide --dest evals/vide/results/2026-11-14
```

Use one `--out` folder per skill: `aggregate_benchmark.py` pools every eval in a folder into one
summary. Rerunning `run-trials.mjs` with the same `--out` adds runs after the existing ones instead
of replacing them.

Other runner flags: `--setup with-skill|baseline`, `--model`, `--effort`, `--timeout-minutes`
(default: the task's, else 20), `--max-budget-usd` (per trial), `--disable-plugins a@m,b@m` (adds
`enabledPlugins: false` entries, belt and braces), and `--keep-projects` (keeps each trial's project
copy for inspection).

### What a trial records

```
<out>/eval-<id>-<name>/eval_metadata.json
<out>/eval-<id>-<name>/<with_skill|without_skill>/run-<n>/
  run.json          status, skills loaded, hooks fired, tokens, cost, wall time, changed files
  grading.json      automatic checks in skill-creator's grading.json shape
  timing.json       total_tokens and total_duration_seconds, which aggregate_benchmark.py reads
  metrics.json      trimmed init event, isolation result, tool calls, token breakdown
  transcript.jsonl  the stream-json transcript
  outputs/          changes.diff, the changed files, and the final message
<out>/eval-<id>-<name>/judge/pair-<n>/
  mapping.json      which run is A and which is B (written outside the judge's view)
  comparison.json   the judge's scores, in skill-creator's comparison.json shape
```

A trial's status is `ok`, `failed`, `timeout`, or `contaminated`. Failed and timed-out trials stay in
the results: every grading starts with the expectation "The trial finished without an error or
timeout", and a trial that breaks before grading still gets a `grading.json` that fails it.

### Trial permissions

Trials run with `--permission-mode acceptEdits` and `--permission-prompts none`: edits inside the
project are allowed, read-only commands inside it need no prompt, and these commands are
pre-approved: `rojo sourcemap`, `luau-lsp analyze`, `selene`, `stylua`, `git status`, `git diff`,
`WebFetch`, and `WebSearch`. Anything else that would ask for approval is denied. Chained shell
commands (`a && b`, `cd x; y`) count as one command and are usually denied; the sandbox README tells
the agent to run each check on its own, and in the smoke test agents recovered by doing that.

## Task files

One JSON file per task, for example `evals/vide/tasks/block-picker.json`:

```json
{
  "id": 1,
  "name": "block-picker",
  "skill": "vide",
  "prompt": "Add a Vide UI that lets the player pick the block type to place ...",
  "setup_files": [{ "from": "fixtures/Placement.luau", "to": "src/ReplicatedStorage/Shared/Placement.luau" }],
  "auto_checks": ["luau-lsp", "selene", "stylua"],
  "checks": [
    { "type": "any_file_matches", "dir": "src", "ext": ".luau", "pattern": "require\\(.*Vide", "text": "The UI requires Vide" },
    { "type": "file_not_matches", "path": "src/StarterPlayer/StarterPlayerScripts/Main.client.luau", "pattern": "Instance\\.new\\(\"ScreenGui\"" },
    { "type": "command", "run": ["lune", "run", "tools/check"], "expect_exit": 0 }
  ],
  "rubric": ["Uses Vide components and sources idiomatically", "Fits phones and monitors"],
  "timeout_minutes": 20
}
```

- `id`, `name`, `prompt`, and `rubric` (1 to 12 criteria for the judge) are required.
- `skill` names the skill expected to load in with-skill; `run.json` records whether it did.
- `setup_files` (paths relative to the task file) are copied into the project and committed before
  the trial, so the diff shows only the trial's work.
- `auto_checks` defaults to all three and runs on the trial's changed Luau files. A trial that
  changes no Luau file fails them. Use `[]` for tasks with no code changes.
- `checks` types: `file_exists`, `file_absent`, `file_matches`, `file_not_matches` (`path`,
  `pattern`, optional `flags`), `any_file_matches` (`dir`, `pattern`, optional `ext`), and `command`
  (`run` as an argument array, no shell; optional `expect_exit`, `timeout_seconds`). Paths must be
  relative and stay inside the project.

The sandbox is a Baseplate place: `Workspace.Baseplate` (top at Y = 0) and a `SpawnLocation`, code
under `src/`, and Vide at `ReplicatedStorage.Packages.Vide`. Its `README.md` tells the agent the
layout and the check commands. The demo feature for tasks is block placement on the Baseplate with a
Vide UI to pick the block type (brick, dirt, grass, window, wood).

## Trigger tests

```sh
python evals/harness/trigger_eval.py eval --eval-set evals/vide/triggers.json \
  --plugin-dir "<worktree>/plugins/roblox-dev" --skill vide --sandbox <scratch>/sandbox \
  --runs-per-query 3 --num-workers 5 --model opus --out <scratch>/vide-triggers.json

python evals/harness/trigger_eval.py loop --eval-set evals/vide/triggers.json \
  --plugin-dir "<worktree>/plugins/roblox-dev" --skill vide --sandbox <scratch>/sandbox \
  --max-iterations 5 --model opus --out <scratch>/vide-loop.json
```

The eval set uses skill-creator's format, `[{"query": "...", "should_trigger": true}, ...]`. This
wraps skill-creator's `run_eval.run_eval` and `run_loop.run_loop` and swaps two functions, because
the originals can't run here as they are:

- `run_eval.py` reads `claude`'s output with `select()`, which fails on pipes on Windows.
- It tests a temporary `.claude/commands/` file with the candidate description, under the machine's
  full configuration. A user-scope plugin with the same skill descriptions, or hooks that suggest
  skills, makes the model pick that plugin's skill, which counts as "not triggered".

The replacement copies the plugin into a temp folder with the candidate description, runs it under
the same isolation flags as trials, fails the query if the init event shows contamination, and
counts a trigger when the session loads `roblox-dev:<skill>` with the Skill tool (or reads its
`SKILL.md`) before it edits a file or makes 8 tool calls. The description rewriter
(`improve_description._call_claude`) runs isolated too.

## Smoke test

`smoke/block-catalog.json` is a tiny task (add a block type catalog module) run against the fixture
plugin, whose `block-catalog` skill sets a file path, a type, and colors from a `references/` file.
Results from 2026-11-13 are in `smoke/results/` (2 trials per setup, Opus, with transcripts):

| | with-skill | baseline |
|---|---|---|
| Status | ok 2 | ok 2 |
| Target skill loaded | 2/2 | 0/2 |
| Pass rate | 0.93 | 0.86 |
| Total tokens per trial | 157,673 and 161,425 | 197,966 and 146,137 |
| Output tokens per trial | 1,891 and 2,013 | 4,472 and 3,087 |
| Wall time per trial | 36.9 s and 42.9 s | 83.2 s and 62.1 s |
| Cost per trial (reported by `claude -p`) | $0.164 and $0.172 | $0.223 and $0.165 |

Judge runs: about 8,000 tokens, 21 s, and $0.064 each. The judge preferred the baseline in both
pairs (mean score 9 vs. 7.25): the fixture skill dictates conventions rather than helping, and the
judge doesn't know them. That's expected for a smoke test of the plumbing.

Total tokens are mostly cache reads (about 90 percent): every model request re-reads the whole
conversation from the cache, and the first request of a trial is already about 18,000 tokens. Total
tokens therefore grow with the number of turns; output tokens and cost track the work better. Real
tasks take more turns, so measure them in the pilot.

## Known limits

- `--restricted` also ignores the project's own `.claude/settings.json`. If the game template later
  ships project settings (permissions or hooks), trials won't apply them.
- Trials can't use Studio. Tasks have to be judgeable from files.
- Hook events show the hook's event name but not which plugin it came from; the baseline check
  works because a baseline session should run no hooks at all.
- The judge sees each attempt's diff and check results, truncated at 60,000 characters per diff,
  with `roblox-dev:<skill>` names replaced by `<skill>`.
