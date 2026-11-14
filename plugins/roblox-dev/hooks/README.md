# roblox-dev hooks

Claude Code hooks that make sure the right skills are loaded before Luau edits and that edited Luau passes the project's checks. `hooks.json` wires them up. They watch Luau files (`.luau`, `.lua`) in a Rojo repo (a folder with a `default.project.json`) or a pesde workspace, and leave every other file alone. Each hook fails open: if it errors, the tool call or turn goes ahead.

## `skill-gate.mjs` (PreToolUse: Edit, Write, MultiEdit)

Denies a Luau file edit until the skills it needs are loaded, and names them in the deny reason so Claude loads them and retries. Every edit needs `roblox-dev:luau-style-guide` and `roblox-dev:code-comments`. Vide code adds `vide` (plus `vide-ui-labs` for components and stories, `vide-charm` for Charm state), specs add `roblox-testing`, and a new script or a new `require` adds `game-architecture`. Only skills loaded under the `roblox-dev:` name count, so a same-named skill from another plugin doesn't satisfy it. Edits inside `roblox_packages` are denied outright. After three denials in a row it steps aside, in case it is missing a load.

## `after-edit.mjs` (PostToolUse: Edit, Write, MultiEdit)

Checks the lines an edit added against mechanical conventions (em dashes or `--` used as a dash in comments, text on a `--[[` line, one-line guard clauses, British spellings) and reports any it finds to Claude as context. It never blocks.

## `skill-hints.mjs` (UserPromptSubmit, PostToolUse: Read, SessionStart: compact)

Suggests skills early. A prompt that mentions UI, performance, specs, Rojo, and similar topics gets a hint naming the matching skills not loaded yet. A Read of a Vide file or a spec names the skills the gate will ask for. After compaction it lists the skills that compaction cut short or dropped.

## `verify-gate.mjs` (Stop)

When Claude finishes a turn that edited Luau files (directly or through subagents), runs `luau-lsp analyze`, `selene`, and `stylua --check` on those files from the project root, and blocks the stop with the findings. It looks for the tools on PATH and in Rokit's bin (`~/.rokit/bin`). A check is skipped with a one-line note when its tool is missing or the project lacks what it needs to give true answers:

- `luau-lsp analyze` needs Roblox type definitions (`globalTypes*.d.luau` in the project root or `types/`, or a local file under `luau-lsp.types.definitionFiles` in `.vscode/settings.json`) and a `sourcemap.json`.
- `selene` needs a `selene.toml`.
- `stylua` needs a `stylua.toml` or `.stylua.toml`.

It blocks once per prompt: the next stop goes through, so Claude can explain a finding it chose to leave.

## Tests

`npm test` from the repo root runs `test/hooks.test.mjs`, which pipes hook JSON into each hook against transcripts and a small Rojo repo it writes to a temp folder. The test that runs fake tools end to end uses shell scripts, so it is skipped on Windows and runs in CI.
