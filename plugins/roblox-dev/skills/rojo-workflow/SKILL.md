---
name: rojo-workflow
description: Working on a Roblox game kept in Git and synced into Studio by Rojo (a repo with a default.project.json) - how files map into the place, editing scripts as files, rojo serve into your own dev place, keeping rojo serve alive after deletes and renames, one worktree and port per agent, writing Studio edits back with syncback, and shared code from pesde packages, Module Loader included. Load it before the first edit, new file, or Studio change in such a repo; before installing or bumping packages or changing a shared package; before running agents in parallel; and when Rojo, pesde, or a sync misbehaves.
---

# Rojo workflow

In a Rojo repo, Git is the source of truth. Code lives in files under `src/`, and `rojo serve`
syncs them into the developer's dev place in Studio, where a connected Studio MCP still analyzes,
tests, and playtests. This skill covers how files map to the place, how changes travel, and how
shared code and Studio-side edits get into Git. The other skills keep their rules; where one
assumes code is edited in Studio, it points to its own Rojo reference.

**The mode.** A `default.project.json` holding a `tree`, in the session's folder or a parent,
means Rojo mode. A repo with several places may keep one project per place (for example
`places/<name>/default.project.json`): a file in a place folder belongs to that place, and code
outside the place folders to all of them. Without any project, the place is edited in Studio as
the other skills describe.

## Files and the place

`default.project.json` mounts folders onto the DataModel: usually `src/<Service>` onto each
service and `roblox_packages` (pesde's install folder) onto a `Packages` folder. Read it for the
exact mounts before creating a file.

| File | Becomes |
|---|---|
| `Name.luau` | ModuleScript `Name` |
| `Name.server.luau`, `Name.client.luau` | Script, LocalScript |
| `Name.spec.luau`, `Name.story.luau` | The ModuleScripts `Name.spec` (a Jest spec) and `Name.story` (a UI Labs story) |
| `Name/init.luau` (or `init.server.luau`, `init.client.luau`) | The script `Name`, with the folder's other files as its children |
| A folder without an `init` script | Folder |
| `Name.meta.json` beside a file, `init.meta.json` in a folder | That instance's `attributes`, plus `properties` such as `Tags` and `IconTint` |
| `Name.model.json` | Instances in readable JSON (values, configurations) |
| `Name.rbxm` | A binary model: Models, Parts, GUIs |

Attributes live in `.meta.json` as real JSON values: booleans for flags, numbers for numbers.

```json
{
  "attributes": {
    "RelocateToServerScriptService": true,
    "ServerOnly": true
  }
}
```

Save every JSON file as UTF-8 without a byte order mark: Rojo can't parse a project or meta file
that starts with one. Windows PowerShell 5.1's `Set-Content` and `Out-File` add a BOM, so write
JSON with your file tools.

`roblox_packages/`, `sourcemap.json`, and build output are generated; keep them in `.gitignore`.

## Changing code

1. Edit and create files with your file tools. The next sync overwrites a script edited in
   Studio, and Git never sees that edit.
2. `rojo serve` pushes each saved file into Studio. Confirm the new text arrived (read the
   script's source in the place) before checking it: a check that starts too early runs the old
   code. A failing line number that didn't move with your edit means exactly that.
3. **After deleting, moving, or renaming any file or folder, confirm `rojo serve` is still
   running** (see Keeping `rojo serve` alive). Rojo 7.7.x crashes on these, and Studio then
   silently stops receiving changes.
4. Check the change in the place: analyze the changed scripts, run the specs the change reaches
   (the `roblox-testing` skill), lint UI, and playtest. Local tools (`luau-lsp analyze`,
   `selene`, `stylua --check`) check files without Studio.
5. `git status` shows only the files you meant to change. Review with `git diff`. Commit on your
   own branch.

## The dev place

- **Serve only into your own dev place.** List its place id in `servePlaceIds` in
  `default.project.json`; Rojo then refuses to live-sync into any other place, so a stray connect
  can't overwrite a shared or live place. Each developer adds their own dev place's id.
- **The dev place is a build of the repo.** Make every change in files. In edit mode, use the
  place to read, analyze, run specs, and playtest. A change made there in Studio (a script edit,
  a property, an attribute or tag, a new instance under a synced folder) is replaced by the next
  sync or never reaches Git, even as a quick test. Route each such change into its file, and
  write genuine Studio-side work back as Studio edits back into Git describes.
- **Several connected places:** when more than one Studio window is connected to the MCP, target
  every change at the intended place explicitly.
- **Know which code the dev place runs before trusting a check.** It runs what the connected
  `rojo serve` serves: the folder that server started in, on whatever branch is checked out there.
  Merging a pull request changes nothing in that folder until it is pulled. When more than one
  checkout or server exists, confirm a change unique to the code under test is in the place
  before reading a test, a playtest, or a bug report from it.
- Live sync can't set properties scripts can't set (collision groups,
  `TouchesUseCollisionGroups`, `VolumetricAudio`, and similar). After such a service setting
  changes in the project, build the place (`rojo build default.project.json -o build/dev.rbxl`,
  creating `build/` first) and have the user publish that build over their dev place.

## Keeping `rojo serve` alive

Rojo 7.7.0 and 7.7.1 crash when a watched file or folder disappears before Rojo handles its
change event (`Rojo crashed!` ... `change_processor.rs`; rojo-rbx/rojo#1314, #1338, #1349). Agents
delete, move, and rename files often, so check after every such step:

- **When you started `rojo serve`** (as a background process), read its output for
  `Rojo crashed!` or confirm the process is still running.
- **When the user runs it**, confirm the project's port still listens (`servePort`, default
  34872): `netstat -ano | findstr :34872` on Windows, `lsof -i :34872` elsewhere.
- **If it stopped**, restart it (`rojo serve`, or with `--port <port>` for a second server) and
  ask the user to click Connect in the Rojo plugin. Then confirm your last change reached Studio.

Stop `rojo serve` before a step that deletes or rewrites many watched files at once, and restart
it afterward: bulk folder deletes, a git command that rewrites the working tree under `src`
(`checkout`, `switch`, `pull`, `rebase`, `reset`, `clean`, `stash`), `pesde install`, and
`rojo syncback`. Once Rojo ships the fix (PR #1350), a release with it ends the need for these
checks.

## Parallel agents and second branches

Give every agent, and every second branch, **its own git worktree and its own `rojo serve`
port.** Two agents editing one folder overwrite each other's work, and two servers syncing into
one place fight over it.

1. `git worktree add ../<repo>-<task> -b <branch>` from the main checkout.
2. In the new worktree, run `pesde install`: a worktree holds only tracked files, so
   `roblox_packages` and `sourcemap.json` start missing.
3. Start `rojo serve default.project.json --port <free port>` there. Each worktree takes a port no
   other running server uses.
4. Each agent works against its own Studio window and dev place. The Rojo plugin connects to one
   server at a time: the user points that window's plugin at the worktree's port, and back when
   the work merges.
5. Stop the worktree's server before removing the worktree (`git worktree remove`).

## Studio edits back into Git

`rojo serve` only syncs files into Studio. Anything genuinely built in Studio under a mounted
folder (a script's child model or GUI, a value, attributes or tags on a synced instance, service
settings the project file holds) has to be written back to its file, or the next sync replaces it:

- **One model or GUI:** export it over its own `.rbxm` (Studio's **Save to File**, or the MCP's
  export-a-model action).
- **A whole session:** the user saves the place as an `.rbxl` in the repo root (keep `*.rbxl` in
  `.gitignore`). Stop `rojo serve`, then run `rojo syncback default.project.json --input
  <place.rbxl>` (`--list` or `--dry-run` previews the changes first). Keep installed packages out
  with the project's `syncbackRules` (`ignoreTrees` for the `Packages` folders). Read the whole
  `git diff` and keep only the intended changes.
- Studio's state wins for everything a syncback covers, so sync files into Studio before the
  Studio work starts.
- Keep instance-reference attributes out of synced content: Rojo can't read them yet
  (rojo-rbx/rojo#1357), and a build silently drops or misplaces them. Reach modules with string
  requires and instances by tag, name, or an id attribute.

## Shared code: pesde packages

Libraries and systems shared between games come from pesde packages: the pesde registry, Wally
packages through pesde's Wally support, and Git repositories (your own shared package repo
included). `pesde.toml` lists each under its alias, and they install into `roblox_packages`.

- **Requiring:** game code requires a package through the link pesde writes for its alias:
  `require("@game/<Packages folder path>/<Alias>")`. Never write the `.pesde/...` path into code:
  it names the installed version and changes with every upgrade.
- **Installing:** `pesde install`, with `rojo serve` stopped. Commit `pesde.toml` and
  `pesde.lock`. Run it again after changing `pesde.toml`, after pulling a change to either file,
  and in every new worktree.
- **Installed files are read-only.** An install replaces everything in `roblox_packages`, and
  pesde hardlinks those files to a store other projects share, so an edit there changes their
  copies too. Configure a package through its own API (a setup module calling its registration
  functions) or the attributes it documents.
- **Module Loader** installs through pesde from Wally:
  `ModuleLoader = { wally = "crusherfire/module-loader", version = "=4.0.1" }`. Use 4.0.1 or later:
  earlier versions can't relocate modules under folders with dots in their names, which pesde's
  `.pesde` and version folders have. Where it mounts and how its settings are set are in the
  reference below.
- **Changing shared code:** edit it in its own repo on a branch, with specs of the package's
  behavior there, and push. In the game, point the dependency's `rev` in `pesde.toml` at that
  commit hash, reinstall, and test in the dev place.

Before adding a dependency, a shared package, or a module to one, and before installing Module
Loader, read [references/shared-packages.md](references/shared-packages.md): dependency forms,
the Wally and sourcemap setup, package layouts, and requires inside a package.

## The map

When the project mounts the world from snapshot files (for example `map/Map.rbxm` onto
`Workspace.Map`) that builders edit in a separate Build place, read
[references/map.md](references/map.md) before pulling the map, adding code that needs a new map
piece, or moving tuning values out of the map.

## CI and deploys

`.github/workflows/` runs the checks on every pull request (lint, analysis, a build, and the Jest
suite through Open Cloud); the workflow files and their README name the secrets and places. When
a merge to `main` publishes to a staging place, merging is deploying.

- Before a merge that publishes, ask the user to close every Studio window on the target place:
  the publish fails with a 409 conflict while it is open, and has to be rerun.
- Once a pull request is handed to the user to merge, push nothing more to its branch: they may
  merge at any moment, and later commits miss the merge. Further changes go in a new branch and
  pull request.

## When something misbehaves

A protocol-version error in the Rojo plugin, a port already in use, two different `rojo` binaries
on PATH, Rokit's "Failed to find tool", luau-lsp without types, a JSON parse error at line 1, or
a stale `index.lock`: read [references/troubleshooting.md](references/troubleshooting.md) for the
confirmed causes and fixes before trying anything else.
