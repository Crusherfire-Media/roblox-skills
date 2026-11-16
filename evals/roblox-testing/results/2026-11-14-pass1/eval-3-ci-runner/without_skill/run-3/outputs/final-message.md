I've written the workflow at `.github/workflows/specs.yml` and the task script at `ci/run-specs.luau`, and added a CI section to `README.md`. None of it has been run: I couldn't reach Roblox, and running even `rojo --version` here was blocked. So the first real run will be your test.

**How it works**
1. It installs the tools from `rokit.toml`, then runs `pesde install --locked`. The root `pesde.lock` includes `test_packages`, so that one install also brings in Jest.
2. It builds `default.project.json` with Rojo and publishes the result as a new version of the CI place. It records the version number that comes back.
3. It sends `ci/run-specs.luau` as a Luau Execution task aimed at that exact version, so two pull requests running at once can't swap the place out from under each other. It checks the task's status until it finishes, then prints the task logs (Jest's normal output) in a collapsible group in the job log.
4. The script returns a summary of the run. The job fails if the task fails, if any test fails, or if any spec file errors while loading. Each failing test gets its own error note on the run, and the job summary shows a pass/fail table.

**Project changes:** I didn't change `default.project.json`. The `globIgnorePaths` entry only stops `src/ServerScriptService/Tests` being picked up a second time through ServerScriptService's own folder. The explicit `Tests` entry still puts `Specs` and `Packages` into the build, which the README's layout table also shows. If you'd rather keep specs out of your real game's build, the fix is a separate CI project file.

**Assumptions to check on the first run**
- **Jest without `debug.loadmodule`:** task scripts can't call it, so the script sets `_G.__NO_LOADMODULE__ = true` before loading Jest. I believe Jest Roblox reads this and falls back to plain `require`, but I haven't confirmed it for 3.20.1. As a result, modules are shared across spec files instead of loaded fresh for each, and `jest.resetModules`/mocking modules won't isolate them the way they do in Studio. The script and README both note this.
- **No specs counts as a failure.** The Specs folder currently holds only `jest.config`, so the first run will fail with "Jest found no spec files…" until you add a spec. I chose this so a broken build or a `testMatch` that matches nothing can't show a green check. To allow empty runs instead, drop the `numTotalTestSuites > 0` check in the script.
- **Task timeout is 300s**, which I believe is Open Cloud's limit. It's the `TASK_TIMEOUT` setting at the top of the workflow.
- **Publishing:** versions are published rather than saved, because I wasn't sure tasks can run against a saved version. Every run overwrites the live CI place, so don't point `ROBLOX_PLACE_ID` at a real game.
- **API key permissions:** `universe-places:write`, plus `universe.place.luau-execution-session:read` and `:write`, on the CI universe.
- **Forks:** pull requests from forks don't get secrets, so their runs fail at the first step with a clear message.
- **Tool commands I couldn't test:** Rokit is installed with its official install script. The `rokit authenticate github` step is only there to avoid GitHub download limits; if it fails, it logs a warning and continues. If `pesde install --locked` complains that the lockfile is out of date, regenerate the lockfile locally and commit it, or drop `--locked`.