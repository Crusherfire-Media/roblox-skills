I've written the workflow, the Luau task script, and the one project change the build needs. None of it has run against Roblox. The Luau script passes stylua, selene and `luau-lsp analyze`. I couldn't run the Rojo build or a YAML parse because both needed permission, and nobody was here to approve it.

## What I added
- **`.github/workflows/specs.yml`**: runs on every pull request, and can also be started by hand. Steps:
  1. Checks the three secrets and fails with a clear message if one is missing.
  2. Installs the tools in `rokit.toml` using `CompeyDev/setup-rokit`.
  3. Runs `pesde install --locked` and checks that Jest is installed under `test_packages`.
  4. Builds the place.
  5. Uploads the build as a new saved version of the CI place.
  6. Starts one Luau Execution task tied to that exact version, so pull requests sharing the CI place can't run each other's code.
  7. Polls the task until it finishes, with its own time limit, prints the task's logs, and fails the job if the task failed.

  It waits and retries when Roblox says to slow down (HTTP 429). It only retries other errors on read requests, so it never starts a task twice. A concurrency group cancels the older run when you push again.
- **`ci/run-specs.luau`**: runs Jest over `ServerScriptService.Tests.Specs` and prints a one-line summary. It calls `error()` when a spec fails, because otherwise the task counts as successful even with failing specs.
- **Project change for the CI build**: on a server, Jest needs `ServerScriptService.LoadStringEnabled` turned on. The workflow creates `ci.project.json` at build time by adding that setting to `default.project.json` with `jq`.
  - Your live game keeps loadstring off.
  - There's no second project file to keep in sync.
  - `ci.project.json` is added to `.gitignore`.
- **README**: a short CI section.

## Assumptions and things to check on the first run
- **The run fails until you have a spec.** The repo has no specs yet, and the script treats "no specs ran" as a failure, so the first pull request will go red until you add one. I did this on purpose: a green run that tested nothing would hide a broken build. If you'd rather it pass while empty, delete that check in `ci/run-specs.luau`.
- **API key permissions:** it needs `universe-places:write` and `luau-execution-sessions` read and write, on the CI universe.
- **Saved versions:** the upload uses `versionType=Saved`, so the CI place is never published live. I'm fairly sure tasks can run against a saved version. If task creation is rejected, change it to `Published`.
- **Forks:** pull requests from forks don't get your secrets, so they will fail at the secrets check.
- **Installing packages:** I assumed `pesde install` at the root also installs the `test_packages` workspace. If it doesn't, the step falls back to installing it directly.
- **Studio vs CI:** specs run on a server in CI, where `RunService:IsServer()` is true. In Studio's edit mode it's false, so a spec that relies on edit mode can pass in Studio and fail in CI.
- **Timeouts:** each task stops after 300 seconds. The polling gives up after 13 minutes and the job after 20. Roblox can occasionally report a task as `INTERNAL_ERROR` after about 11 minutes. The job labels that as a Roblox problem: rerun it rather than changing code.

I haven't committed anything.