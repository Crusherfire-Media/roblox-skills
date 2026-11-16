I've written the workflow, the Luau script and a CI-only project file, but none of it has been run. Shell commands needed approval this session and nobody could grant it, so I couldn't build the place with Rojo, run StyLua or Selene, or lint the YAML. Nothing is committed.

## What I added

- **`ci.project.json`**: a copy of `default.project.json` with one real change, turning on `ServerScriptService.LoadStringEnabled`. Open Cloud tasks don't have `debug.loadmodule`, which Jest normally uses to load modules. Jest's fallback loads modules from `Script.Source`, and that needs loadstring enabled. The setting is only in the CI build, never in `default.project.json`. Since Rojo project files can't extend one another, the workflow fails if the two files differ by anything other than the name and that property.
- **`ci/run-specs.luau`**:
  - It runs Jest with `ci = true` (missing snapshots fail instead of being written) and verbose output on the `Tests.Specs` folder.
  - It returns a summary: whether the run passed, the counts, and up to 50 failures with their messages.
  - It raises an error if the place is missing `Tests`, `Packages`, `Specs` or `jest.config`, or if Jest doesn't finish.
- **`.github/workflows/specs.yml`**: runs on every pull request (and can be started by hand). In order, it:
  1. checks that the three secrets are set;
  2. installs the tools listed in `rokit.toml` and runs `pesde install --locked`;
  3. builds the place;
  4. uploads it as a **Saved** version, so the CI place's live version is never touched;
  5. starts the task on exactly that version and polls until it finishes;
  6. prints the Jest output from the task logs;
  7. writes a results table and the failures to the job summary.

  The job passes only if the task finishes normally and the summary says the run succeeded.
- **`README.md`**: a short CI section listing the secrets and the API key permissions. I also changed the old line that said specs only run in Studio.

## Calls I made

- **No specs counts as a failure.** The repo has no `*.spec.luau` files yet, so **the check will fail until you add one.** I chose this so that a build that quietly dropped the specs can't pass.
- **API key permissions:** `universe-places:write` to upload versions, plus `universe.place.luau-execution-session:read` and `:write`. Limit the key to the CI experience.
- **Concurrency:** a new push to a PR cancels that PR's run if it's still going. Each run tests only the version it uploaded, so PRs can't test each other's builds. Roblox limits task creation to 5 per minute per key owner; curl retries when it gets HTTP 429 or a server error.
- **Pull requests from forks** don't get repository secrets, so the job fails for them with a clear message.

## Things to check when you try it

- **Jest without `loadmodule`** is the biggest risk. A Roblox staff post says Jest Roblox can now load modules through `Script.Source`, but I couldn't confirm that version 3.20.1 does. If the logs show `debug.loadmodule is not enabled`, try a newer Jest version.
- **`CompeyDev/setup-rokit@v0.1.2`** is a third-party action, and I'm not certain of the version tag. If the step can't be found, install Rokit with its install script instead.
- **`pesde install --locked`** in CI is untested. It may also need Lune for the `scripts_rojo` dev dependency.
- **The results summary's field names** come from Jest's results object as it works in JavaScript Jest. If the job log says the task didn't return a summary table, those names are the first place to look.

Sources:
- [Open Cloud Luau Execution reference](https://create.roblox.com/docs/cloud/reference/features/luau-execution.md)
- [LuauExecutionSessionTask endpoints](https://create.roblox.com/docs/cloud/reference/LuauExecutionSessionTask)
- [Roblox/place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo) (upload endpoint, Saved versions, task flow)
- [DevForum: Open Cloud Engine API for Executing Luau](https://devforum.roblox.com/t/beta-open-cloud-engine-api-for-executing-luau/3172185?page=3) (Jest, `Script.Source` and `loadmodule`)
- [Jest Roblox: Getting Started](https://roblox.github.io/jest-roblox-internal) and [runCLI options](https://roblox.github.io/jest-roblox-internal/cli)
- [ServerScriptService.LoadStringEnabled](https://create.roblox.com/docs/en-us/reference/engine/classes/ServerScriptService.md)