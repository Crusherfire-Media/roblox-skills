# Troubleshooting Rojo, pesde, and the toolchain

Confirmed causes and fixes, checked against Rojo 7.7.1, Rokit 1.2.0, pesde 0.7.4, and luau-lsp
1.70 (November 2026). Find the symptom, apply its fix, then confirm the original step works.

## `rojo serve` stopped: "Rojo crashed!"

```
[ERROR rojo] Rojo crashed! You are running Rojo 7.7.1.
[ERROR rojo] Details: called `Result::unwrap()` on an `Err` value: Os { code: 2, kind: NotFound, ... }
[ERROR rojo] in file src\change_processor.rs on line 179
```

A watched path disappeared before Rojo handled its event: a delete, move, or rename, a folder
module replaced by a file module, a branch switch, a package install, or an editor that saves
through a temp file. It's a 7.7.0 regression, still in 7.7.1 (rojo-rbx/rojo#1314, #1338, #1349);
the fix is PR #1350. Restart `rojo serve`, click Connect in the Studio plugin, and confirm your
last change reached Studio. luau-lsp's `rojo sourcemap --watch` may die the same way; see "luau-lsp
has no types" below.

## The plugin says "different protocol version"

```
Found a Rojo dev server, but it's using a different protocol version, and is incompatible.
```

or, in Output, `attempt to index number with 'protocolVersion'`. Rojo 7.7 speaks protocol 5, so a
7.6 plugin and a 7.7 server (or the reverse) can't talk. Run `rojo --version` in the project
folder, then update the side that's behind: bump `rokit.toml` and run `rokit install`, or update
the plugin. `rojo plugin install` installs the plugin that matches your CLI exactly; remove the
marketplace copy so only one loads.

## "Could not start the Rojo server ... The address may already be in use"

Another `rojo serve` is running on that port (another terminal, another worktree, or a server an
agent started in the background). Find it with `netstat -ano | findstr :34872` (Windows) and end
that process, or start this one with `--port <other port>` and enter that port in the plugin.

## Two different `rojo` on PATH

`where.exe rojo` (Windows) or `which -a rojo` lists both `.rokit\bin\rojo` and `.pesde\bin\rojo`,
and `rojo --version` disagrees with `rokit.toml`. `pesde init` with `pesde/scripts_rojo` adds a
`rojo` dev dependency (`pesde/rojo`, 7.7.0 at the time of writing), and pesde links its binary into
`~/.pesde/bin`; whichever folder comes first on PATH wins. Pick one owner: remove the `rojo` dev
dependency from `pesde.toml` and run `pesde install` so Rokit's Rojo is used (scripts_rojo calls
whatever `rojo` is on PATH), or drop Rojo from `rokit.toml`. Then match the plugin.

## Rokit: "No manifest was found" or "Failed to find tool"

Rokit's `rojo`, `stylua`, and `selene` are shims that read the nearest `rokit.toml`. Run tools from
inside the project folder. After `rokit.toml` changes (a version bump, a fresh clone, an agent's
edit), run `rokit install`; a listed version that isn't installed fails with `os error 2` or
`os error 3`.

## "is not recognized" right after installing a tool

Terminals and VS Code keep the PATH they started with. Close every terminal and every VS Code
window, then reopen; restart Windows if that isn't enough.

## A JSON parse error at line 1, column 1

```
File contains malformed JSON: ... JSONC parse error ... Unexpected token on line 1 column 1
```

The file starts with a UTF-8 byte order mark. Re-save it as UTF-8 without BOM (in VS Code: the
encoding in the status bar, **Save with Encoding**, **UTF-8**). Windows PowerShell 5.1's
`Set-Content` and `Out-File` write a BOM.

## luau-lsp has no types: unknown requires, no autocomplete

The VS Code extension runs `rojo sourcemap default.project.json --output sourcemap.json --watch` in
the workspace root, with the `rojo` on PATH. It fails when VS Code started before Rokit was on
PATH, when the opened folder isn't the project root, when the project file has another name
(`luau-lsp.sourcemap.rojoProjectFile`), or after a Rojo crash. Open the project folder itself,
then run **Luau: Regenerate Sourcemap**. For a one-off sourcemap from the terminal, run
`rojo sourcemap default.project.json --output sourcemap.json`. Wally packages installed through
pesde need the `sourcemap_generator` script in `pesde.toml` to get types.

Instances that exist only in Studio (parts you built there) never appear in the sourcemap; the
Luau Language Server Companion Studio plugin supplies them when `luau-lsp.plugin.enabled` is on.

## selene flags `game`, `workspace`, or `script` as undefined

`selene.toml` needs `std = "roblox"`.

## Git: "Unable to create '.../.git/index.lock': File exists"

Another git process holds the lock, often a background `git status`. Wait and retry; if no git
process is running, delete `.git/index.lock`.

## `stylua --check` fails on every file

The files were checked out with CRLF line endings. A `.gitattributes` with `* text=auto eol=lf`,
followed by a fresh checkout, fixes it.
