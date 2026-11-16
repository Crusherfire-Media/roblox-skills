I've written the workflow and the scripts, but none of it has run yet: Roblox isn't reachable from here, and the sandbox also blocked a local `rojo build` and a Python syntax check. Two things to know before you open the first PR:

- **The first run will fail.** The repo has `jest.config.luau` but no `*.spec` files yet, and I made a run that finds zero tests fail on purpose (error: "Jest found no tests under ServerScriptService.Tests.Specs"). It almost always means the build left the specs out, and a silent pass would hide that. To allow an empty suite until you add specs, delete that check in `ci/run-specs.luau`.
- **PRs from forks will fail**, because GitHub doesn't give secrets to fork PRs.

## What I added

- **`.github/workflows/specs.yml`**: runs on every pull request, and you can also start it by hand. It:
  1. installs the tools from `rokit.toml`;
  2. runs `pesde install --locked`, which also installs the Jest packages in `test_packages`;
  3. builds the CI place with Rojo;
  4. uploads it and runs the specs in it.

  If a branch gets a new push while a run is going, the older run is cancelled, so the job doesn't run into Roblox's limit on how fast tasks can be created. The job times out after 20 minutes.
- **`ci/luau_execution.py`**: a small helper the workflow calls (Python standard library only).
  - It uploads the build as a new **saved** version of the CI place, then starts the task on that exact version, so two PRs sharing the CI place can't run each other's code.
  - It checks the task every few seconds and gives up after 13 minutes, since a stuck task can take about 11 minutes to report an internal error.
  - If Roblox says too many requests, it waits as long as Roblox asks before retrying.
  - When the task finishes, it prints the task's logs into the job output. If the task failed, it adds an error note to the PR's checks page and the job exits 1.
- **`ci/run-specs.luau`**: runs Jest on `ServerScriptService.Tests.Specs`.
  - A task only counts as failed when its script throws an error, so the script raises one whenever Jest can't start or any spec fails.
  - Before raising, it prints each failing spec file and test name plus a pass/fail count. These go after Jest's own output because Roblox cuts the log at 450 KB, starting with the oldest lines.
  - StyLua and selene pass on it.
- **Project change**: Jest needs `loadstring`, and a game server only allows that when `ServerScriptService.LoadStringEnabled` is on.
  - The workflow writes a copy of `default.project.json` with that one setting on, named `ci.project.json`, and builds from it. I tried the edit command locally and the setting lands under `ServerScriptService`. I added `ci.project.json` to `.gitignore`.
  - I didn't change `default.project.json`, so your dev place and live game don't get `loadstring`, and there's no second project file to keep in sync.
- I also updated the Tests section of `README.md` and added the new `.gitignore` line. Nothing is committed.

## Assumptions to check when you try it

- **API key permissions**: on the CI experience, the key needs `universe-places:write` plus read and write on `universe.place.luau-execution-session`.
- **Saved versions**: I assumed a task can run on a saved (unpublished) version of the place. If Roblox rejects that, change `versionType=Saved` to `Published` in the helper.
- **Separate experience**: keep the CI place in its own experience. If a spec reaches DataStores, it hits that experience's real data.
- **Dev mode vs. CI**: the specs run on a game server in CI. A spec that relies on Studio's edit mode (there `RunService:IsServer()` is false) can pass in Studio and fail in CI.
- **Things I copied from the existing setup**: the Jest version (3.20.1, which works with this API) and the pesde/Rojo layout. I assumed the `.pesde` links pesde writes into the build load the same way under a server as they do for you in Studio.