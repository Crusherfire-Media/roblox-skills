I've fixed `default.project.json` and added `docs/rojo-workflow.md`. I couldn't confirm the fix works: running `rojo sourcemap` needed approval, and approval isn't available in this session. Please run `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` and start `rojo serve` once before committing. Nothing is committed yet.

## What the merge broke

I compared the file with the commit before the merge (`4b6fdf2`). There were four problems:

1. **A byte order mark (BOM) at the start of the file.** Rojo can't read a project file that starts with one, which is very likely why `rojo sourcemap` fails. I saved the file without it.
2. **`globIgnorePaths` was removed.** That setting stops `src/ServerScriptService/Tests` from being picked up automatically under `ServerScriptService`, so the explicit `Tests` entry can mount it instead. Without it, `Tests` appears twice. I put it back.
3. **The Jest packages were in the wrong place.** They were mounted as `ReplicatedStorage.TestPackages`, so specs couldn't find `ServerScriptService.Tests.Packages.Jest`. That's the "can't find its packages" problem. They're back under `ServerScriptService.Tests.Packages`.
4. **A typo in a path:** `src/StarterPlayer/StarterPlayerScript` (missing the final `s`). That folder doesn't exist, so client scripts weren't syncing.

I kept `servePort: 34872`, which the merge added and which is fine. Every mount now matches a row in the README's Layout table. Both package folders are installed on disk.

## The guide

`docs/rojo-workflow.md` is a short guide for new teammates. It covers:
- **One-time setup:** Rokit, `pesde install` in both folders, and adding your own dev place's id to `servePlaceIds`.
- **The daily loop.**
- **Where changes go:** a table of which kind of change goes in which folder or file, and which folders are generated and must never be edited.
- **What to check while serving:** that the new code actually reached Studio, and that `rojo serve` is still running. Rojo 7.7.0 and 7.7.1 crash when a file is deleted or renamed, and Studio then silently stops updating. It also lists the commands to run only with `rojo serve` stopped.
- **Not breaking the project file:** why the ignore and the explicit `Tests` mount go together, saving without a BOM, how to resolve a merge conflict in it, and running the sourcemap command before committing.

The guide tells each teammate to add their own place id to `servePlaceIds` in the shared project file. That's the usual Rojo practice, but your team might prefer another way. The guide is the only place that says so, so change it there if you do.