I've written the three pieces, but none of it has been run. I couldn't reach Roblox, and the shell commands I tried here were blocked by permissions, so I also couldn't run selene, stylua or a Rojo build on the new files. Your first PR will be the first real test.

**One thing to know first:** there are no `*.spec` files in `Tests/Specs` yet, only `jest.config.luau`. The job fails when no tests run (Jest itself treats that as an error), so add at least one spec before trying it. I made "no tests ran" a failure on purpose: a green check that ran nothing would hide a broken build.

## Files
- **`.github/workflows/specs.yml`** runs on every pull request and can also be started by hand. It:
  1. Fails straight away with a clear message if any of the three secrets is missing.
  2. Installs the tools from `rokit.toml` and runs `pesde install --locked`.
  3. Builds the CI place with Rojo.
  4. Saves the place as a new version through Open Cloud and records the version number.
  5. Creates a Luau Execution task for that exact version and checks its status every 5 seconds, giving up after 15 minutes.
  6. Prints the task logs (Jest's normal colored output), adds one error annotation per failing test, and writes a summary of the run on the job page.
  7. Fails if the task didn't complete, if any test failed, or if no tests ran.
- **`ci/run-specs.luau`** finds `ServerScriptService.Tests`, runs Jest with `ci = true` (so it doesn't write new snapshots), and returns a JSON summary: pass/fail counts plus up to 50 failures, with color codes stripped and long messages cut short. It throws an error if Jest can't run at all.
- **Project change:** Jest normally loads each spec with `debug.loadmodule`. On Open Cloud servers it falls back to `loadstring`, which only works when `ServerScriptService.LoadStringEnabled` is on. So the workflow generates `ci.project.json` from `default.project.json` with that one property added, and builds from it. Generating it means the CI build can't drift from the real project; it's gitignored. `default.project.json` itself is unchanged, so the real game keeps `loadstring` off.
- I also updated the README's Tests section and `.gitignore`.

## Assumptions to check
- **API key permissions:** `universe-places:write`, plus `universe.place.luau-execution-session:read` and `:write`, all on the CI universe.
- **Every run saves a new version of `ROBLOX_PLACE_ID`.** Only ever point it at a throwaway place. Each task is tied to the version its own run saved, so PRs running at the same time don't interfere. A newer push to the same PR cancels the older run.
- **Rokit setup** uses `CompeyDev/setup-rokit@v0.1.2`. I wrote that from memory and couldn't check it here. If that step fails, swap in Rokit's install script followed by `rokit install --no-trust-check`.
- **Endpoints and response fields** (`versionNumber`, `.path`, `.state`, `.output.results`, `.luauExecutionSessionTaskLogs[].messages`) are also from memory of the Open Cloud docs and weren't checked against the live API. The script and workflow print the raw response when something doesn't match, so a mismatch should be easy to spot.
- **Timeout:** each task gets the 300-second execution limit. If the suite grows past that, it will need splitting.
- **Fork PRs** don't get repository secrets, so the job fails for them with a message saying why. I deliberately didn't use `pull_request_target`, because it would run untrusted code with your API key.