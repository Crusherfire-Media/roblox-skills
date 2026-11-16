# CI

| When | Workflow job | Does |
|---|---|---|
| Every pull request and push to `main` | `CI / Checks` | `luau-lsp analyze` with Roblox's types and a sourcemap, then selene and StyLua |
| Every pull request and push to `main` | `CI / Specs` | Builds the place, saves it to the CI place, and runs every spec there in one Luau Execution task |
| A push to `main` (a merged pull request) | `CI / Publish to staging` | Publishes the build to the staging place, after Checks and Specs pass |
| A published GitHub release | `Release / Publish to production` | Publishes the release's commit to the production place, if that commit is on `main` |

Specs and the two publish jobs skip themselves until their place's repository variable exists, so
a new repo starts green.

| Script | Does |
|---|---|
| `install-pesde.sh` | Installs pesde in a CI job from its GitHub release |
| `prepare-test-place.luau <game.rbxl> <test.rbxl>` | Turns on `LoadStringEnabled`, which Jest needs on a game server, and disables server Scripts. Only the CI place gets this |
| `run-tests.luau <test.rbxl>` | Saves the test place as an unpublished version and runs `run-specs-task.luau` in one task pinned to that version. Exits 1 when a spec fails |
| `publish.luau <game.rbxl>` | Removes `ServerScriptService.Tests` and publishes the build as the version players join |

The scripts run on Lune 0.10.5, which doesn't parse `const`, so they use `local`. Run `lune setup`
once for editor types on `@lune/...` requires.

## Setup

### 1. The places

Create three places in Roblox: a CI place for the specs, a staging place, and the production place.
Give the CI place an experience of its own. Specs can reach real data stores, which belong to an
experience, so this keeps tests away from your players' data.

### 2. The Open Cloud API key

A key acts as the account that created it. Create it on a dedicated Roblox account that has access
to these experiences only, so a leaked key can't reach anything else. Publishing counts as that
account publishing, so it has to meet Roblox's publishing requirements: in good standing, at least
2 days old, age checked, and with 2-Step Verification on.

In the Creator Dashboard, under **API Keys**, create a key with exactly these permissions:

| Select API System | Experiences | Operations | Scopes it grants | Used by |
|---|---|---|---|---|
| **assets** | CI, staging, and production | **Read**, **Write** | `asset:read`, `asset:write` | Saving the test place and publishing (Update Asset, Get Operation) |
| **luau-execution-sessions** | CI only | **Write** | `universe.place.luau-execution-session:write` | Creating the spec task and reading its state and logs |

- Keep **Restrict by Experience** on, with only the experiences above.
- Leave **Restrict IP addresses** off. GitHub's runners have no fixed address.
- Roblox expires a key after 60 days without use. A production publish can be that rare, so if a
  release fails with 401, open the key in the dashboard and turn **Enable Key** off and on.

### 3. GitHub

Store the key with the script, run in your own terminal at the repo root. It reads the key from
hidden input, so the key never shows on screen or in your history:

```
powershell -ExecutionPolicy Bypass -File tools/set-api-key.ps1
```

On macOS or Linux, run `bash tools/set-api-key.sh`.

Then set the place and universe ids as repository variables. The ids are in each place's Creator
Dashboard URL: `.../experiences/<universe id>/places/<place id>/...`.

```
gh variable set CI_UNIVERSE_ID --body <id>
gh variable set CI_PLACE_ID --body <id>
gh variable set STAGING_PLACE_ID --body <id>
gh variable set PRODUCTION_PLACE_ID --body <id>
```

Last, add a branch ruleset for `main` in the repo's settings that requires the `Checks` and `Specs`
status checks. Changes then reach `main`, and with it staging, only through a passing pull request.
GitHub offers rulesets on public repos, and on private repos with GitHub Pro, Team, or Enterprise Cloud.

## Publishing endpoint

Both publish and the test upload use the Assets API, `PATCH https://apis.roblox.com/assets/v1/assets/{placeId}`,
then poll the operation it returns for the new version number.

- It's the endpoint Roblox's place publishing guide documents now.
- It saves an unpublished version (`"published": false`) for the specs and publishes
  (`"published": true`) for staging and production, so one permission covers both.
- It needs only the place id.
- `rojo upload` calls the older `universes/v1/.../versions` endpoint with `versionType=Published`
  fixed, so it can't save the unpublished version the specs run against. It also builds straight
  from the project, which would ship the specs and Jest to players.

## When a run fails

- **Specs fail with 429:** Luau Execution allows 5 task creates per minute per key owner and 10
  unfinished tasks per place. The script retries short waits. A long `retry-after` means an hourly
  lockout: rerun the job later. Use your own key, not the CI account's, for any Luau Execution you
  run by hand.
- **Specs end with `INTERNAL_ERROR`:** a Roblox-side failure. The script runs the task once more.
  If it fails again, rerun the job.
- **A spec passes in Studio and fails here:** CI runs specs on a game server, where
  `RunService:IsServer()` is true. In Studio's edit mode it's false.
- **Publishing fails with 409 "Server is busy":** someone has that place open in Studio or Team
  Create. Close it and rerun the job.
- **Specs fail with "ROBLOX_API_KEY is not set" on a pull request from a fork or Dependabot:**
  GitHub withholds secrets from those runs.
