# Specs in CI: Open Cloud Luau Execution

CI runs the whole suite on every pull request: it builds the place with Rojo, uploads it to a
dedicated CI place, and runs a Luau script there through the Open Cloud
[Luau Execution API](https://create.roblox.com/docs/cloud/reference/features/luau-execution). The
script calls Jest and fails the task when Jest reports failures. Roblox's
[place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo) is the reference pipeline.

## How the job works

1. Build the place (`rojo build default.project.json -o build/ci.rbxl`) and upload it as a new
   version of the CI place.
2. Create one Luau Execution task pinned to that version
   (`POST .../universes/{universeId}/places/{placeId}/versions/{versionId}/luau-execution-session-tasks`),
   with the entry script below as `script`. Pinning the version keeps two pull requests that upload
   to the same CI place from running each other's code.
3. Poll the task until its `state` is `COMPLETE` or `FAILED`, then read its logs.
4. Fail the job when the task ends `FAILED`.

## Rules the job follows

- **One task per run.** Task creation is limited to 5 per minute per API key owner, and a place
  allows at most 10 unfinished tasks; past either limit the API answers HTTP 429. Run the whole
  suite in one task, and honor `retry-after` on a 429 instead of retrying in a loop.
- **A `concurrency` group** on the test job, so pushes in quick succession queue (or cancel the
  older run) instead of creating tasks in parallel:

  ```yaml
  concurrency:
    group: luau-execution-${{ github.ref }}
    cancel-in-progress: true
  ```

- **The entry script calls `error()` when Jest reports failures.** A task ends `FAILED` only when
  its script raises an unhandled error; a script that returns normally ends `COMPLETE` even when
  tests failed.

  ```lua
  local ServerScriptService = game:GetService("ServerScriptService")
  local root = ServerScriptService.Tests.Specs

  local status, result = require(ServerScriptService.Tests.Packages.Jest).runCLI(root, {
  	ci = true,
  	verbose = false,
  }, { root }):awaitStatus()

  if status == "Rejected" then
  	error(result)
  end
  if not result.results.success then
  	error("Tests failed")
  end
  ```

- **`LoadStringEnabled` on in the CI place.** Jest loads modules with `loadstring` where
  `debug.loadmodule` isn't available, and a Luau Execution task runs on a game server, where
  `loadstring` needs `ServerScriptService.LoadStringEnabled = true`. Set it in the CI build's
  project file (Roblox's own jest-roblox repo does):

  ```json
  "ServerScriptService": { "$properties": { "LoadStringEnabled": true } }
  ```

  Use Jest Roblox 3.14.0 or later, which runs in Luau Execution.
- **Timeouts on both ends.** A task runs for at most 5 minutes (set the task's `timeout` lower to
  fail sooner). Give the poll loop its own deadline and the job a `timeout-minutes`, since a task
  can occasionally sit in `PROCESSING` and end with `INTERNAL_ERROR` after about 11 minutes.

## What differs from Studio

- **The specs run on a server.** `RunService:IsServer()` is true and `IsClient()` is false, so a
  spec that relies on edit mode's client path passes in Studio and fails in CI. Fake the realm
  boundary instead of relying on either.
- **Nothing boots.** Physics doesn't run, and the place's Scripts and LocalScripts don't start on
  their own, so the Module Loader never runs: specs call what they need, as in Studio.
- **Changes aren't saved.** The task's DataModel changes vanish with it. Cloud data is real,
  though: DataStore calls reach the experience's stores, so keep the CI place in its own
  experience and fake data stores in specs anyway.
- **Logs are capped at 450 KB**, oldest discarded first, and are readable only after the task
  ends. Keep the reporter quiet on a passing run (the `StatusReporter` from [setup.md](setup.md)
  prints one line per file).
- **Printing invalid UTF-8 can hang the task.** Escape binary data (buffers, raw bytes) before
  printing it in a spec.

## Acting on a CI failure

1. Read the job's log for the failing spec files and test names.
2. Rerun each failing spec file in Studio, filtered to it ([running-in-studio.md](running-in-studio.md)).
3. When it passes in Studio and fails in CI, look first at the differences above: realm checks,
   something that assumed a booted game, or edit-mode state.
4. A 429 or an `INTERNAL_ERROR` is infrastructure: rerun the job once the limit resets, without
   changing code.
