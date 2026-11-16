I've fixed `default.project.json` so the place maps exactly as the README's Layout table says, and I've added `docs/rojo-workflow.md`. `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` now succeeds. I checked the resulting tree against the table and it matches.

**What the merge broke** (compared against the version in the first commit):
1. **The file started with a hidden byte order mark** (an invisible marker some Windows tools add at the start of a file). This is why `rojo sourcemap` failed: Rojo can't parse the file with it there (`Failed to parse JSONC`). It was probably saved with a Windows PowerShell command. I removed it.
2. **The Jest packages were in the wrong place.** They had been moved to `ReplicatedStorage.TestPackages`. They belong at `ServerScriptService.Tests.Packages`, and that's why Jest couldn't find them. I moved them back.
3. **A setting was dropped.** The `globIgnorePaths` entry for `src/ServerScriptService/Tests` was gone. Without it the Tests folder risks being mapped twice under `ServerScriptService`. I restored it.
4. **A folder name had a typo.** `src/StarterPlayer/StarterPlayerScript` was missing its final "s", so it pointed at a folder that doesn't exist. I corrected it to `StarterPlayerScripts`.

I kept `servePort: 34872`, which the merge added; it's Rojo's default port, so it changes nothing. The only file changed is `default.project.json`, and I regenerated `sourcemap.json`, which is generated anyway.

**The guide** covers:
- one-time setup, including putting your own dev place id in `servePlaceIds`
- the daily loop of serving, editing files and running the checks
- a table of where each kind of change goes, and why edits made in Studio are lost
- what to check while serving: Rojo 7.7.x crashing after a file is deleted or renamed, confirming new code reached Studio, and being on the right branch and server
- a section on keeping `default.project.json` healthy, built from these four failures, including how to check for the byte order mark

**What I couldn't verify:** I didn't run `rojo serve` against a Studio place or run the Jest specs. A teammate should reconnect and confirm the specs find their packages. Two smaller checks were also blocked by permissions: a Python script to print the sourcemap tree, so I checked it with searches instead, and a .NET call to read the file's first bytes, which I did with `od` instead. Nothing is committed.