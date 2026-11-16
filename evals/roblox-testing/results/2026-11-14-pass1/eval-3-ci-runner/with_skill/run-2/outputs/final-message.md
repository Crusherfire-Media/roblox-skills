I've written the CI setup, but none of it has been run. The session blocked every command I tried, including StyLua, selene, a Python syntax check and a local Rojo build, so the first real check will be your PR.

## What I added

- **`.github/workflows/specs.yml`** runs on every pull request (and can also be started by hand). Steps:
  1. Installs the tools in `rokit.toml` with Rokit.
  2. Runs `pesde install --locked`. This also installs Jest from `test_packages`, which matters because `roblox_packages/` is gitignored.
  3. Builds the place with Rojo.
  4. Hands the build to the helper script below.

  A newer push to the same PR cancels the older run (Open Cloud only allows 5 new tasks per minute). The job times out after 20 minutes.
- **`ci/run-specs.luau`** is the task's script. It runs Jest on `ServerScriptService.Tests.Specs` and raises an error if Jest can't run, or if any spec fails or fails to load. That error is what makes the task, and so the PR, fail. The message lists each failing test by name (up to 50). On success it returns a one-line pass/fail count.
- **`ci/run_luau_task.py`** is a helper I added; it needs nothing beyond the Python that comes with the runner. It uploads the build as a new version of the CI place, starts one task tied to that exact version, and checks on it until it finishes, giving up after 8 minutes. Then it prints the task's logs and fails the job unless the task ended `COMPLETE`. When the API says it's rate-limited, it waits as long as the API asks before retrying.
- **Project changes:**
  - Jest needs `ServerScriptService.LoadStringEnabled` turned on to run on a game server. Instead of turning it on in the real game, the job writes a copy of `default.project.json` with it switched on (`ci.project.json`) and builds from that. I added `ci.project.json` to `.gitignore`.
  - I added a short CI section to `README.md`.

## Decisions I made for you

- **The API key needs two permissions:** `universe-places:write` and `universe.place.luau-execution-session:write`, both for the CI experience.
- **Builds are uploaded as "Saved", not "Published"**, so CI builds never go live to anyone who joins the CI place. If the task step rejects a saved version, change `versionType=Saved` to `Published` in `ci/run_luau_task.py`.
- **A run that finds no specs passes**, with a warning in the log. There are no specs yet, and failing on an empty suite would turn every PR red until the first one lands. Remove `passWithNoTests` from `ci/run-specs.luau` once you have specs, so a broken test pattern can't pass quietly.
- **Use a CI place in its own experience.** Specs there can read and write that experience's real DataStores.
- **PRs from forks will fail**, because GitHub doesn't give them secrets.

## What to watch on the first run

- **Install steps:** I installed Rokit with its official install script and assumed `rokit install --no-trust-check` and `pesde install --locked` work unattended. If the job breaks early, it will probably be here.
- **Jest's loader:** if a spec fails to load with an error about a `..` path inside `roblox_packages`, Jest is refusing one of pesde's links between packages. That would need an extra install step to rewrite those links.
- **Specs that pass in Studio but fail here:** specs run on a server in CI, so `RunService:IsServer()` is true there and false in Studio's edit mode. Code that checks which side it's on will take a different path.
- **Formatting:** StyLua may want small changes to `ci/run-specs.luau`, since I couldn't run it.