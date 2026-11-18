# CI

| When | Workflow job | Does |
|---|---|---|
| Every pull request and push to `main` | `CI / Checks` | Builds every place, then `luau-lsp analyze` on each with Roblox's types and its own sourcemap, then selene and StyLua |
| Every pull request and push to `main` | `CI / Specs` | Saves each place's test build to its place in the CI experience and runs its specs there, one Luau Execution task per place, all at once |
| A push to `main` (a merged pull request) | `CI / Publish to staging` | Publishes every place to the staging experience, after Checks and Specs pass |
| A published GitHub release | `Release / Publish to production` | Publishes every place at the release's commit to the production experience, if that commit is on `main` |

`places.json` at the repo root says where each place goes. Specs and the two publish jobs skip
themselves while its universe for their experience is `null`, so a new repo starts green. Staging
publishes only after the specs pass, so it also waits for the CI experience.

| Script | Does |
|---|---|
| `install-pesde.sh` | Installs pesde in a CI job from its GitHub release |
| `build.luau` | Checks `places.json` against the folders in `places/`, then builds each place into `build/<name>.rbxl` |
| `run-tests.luau` | For each place: turns on `LoadStringEnabled` (Jest needs it on a game server) and disables server Scripts, saves that as an unpublished version of its CI place, and runs `run-specs-task.luau` in a task pinned to that version. Exits 1 when any place's specs fail |
| `publish.luau <staging\|production>` | Removes `ServerScriptService.Tests` from every place's build, then publishes each as the version players join |
| `places.luau`, `open-cloud.luau`, `prepare-test-place.luau` | Modules the scripts share: reading `places.json`, Open Cloud requests, and the test-place changes |

The scripts run on Lune 0.10.5, which doesn't parse `const`, so they use `local`. Run `lune setup`
once for editor types on `@lune/...` requires.

## Setup

### 1. The places

Create three experiences in Roblox: CI for the specs, staging, and production. Each needs the same
places as the repo's `places/` folders. A new game has one place, `main`, which is the start place
every experience already has. Specs can reach real data stores, which belong to an experience, so
a CI experience of its own keeps tests away from your players' data.

### 2. The Open Cloud API key

A key acts as the account that created it. Create it on a dedicated Roblox account that has access
to these experiences only, so a leaked key can't reach anything else. Publishing counts as that
account publishing, so it has to meet Roblox's publishing requirements: in good standing, at least
2 days old, age checked, and with 2-Step Verification on.

In the Creator Dashboard, under **API Keys**, create a key with exactly these permissions:

| Select API System | Experiences | Operations | Scopes it grants | Used by |
|---|---|---|---|---|
| **universe-places** | CI, staging, and production | **Write** | `universe-places:write` | Saving the test place and publishing (Publish a Place) |
| **luau-execution-sessions** | CI only | **Write** | `universe.place.luau-execution-session:write` | Creating the spec task and reading its state and logs |

- Keep **Restrict by Experience** on, with only the experiences above.
- Don't add **assets**. CI doesn't use it, and its operations apply to every asset the account
  can access: it can only be restricted by creator, not by experience.
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

Then fill in `places.json` and commit it. The ids are in each place's Creator Dashboard URL:
`.../experiences/<universe id>/places/<place id>/...`. They aren't secrets.

```json
{
  "universes": { "ci": 111, "staging": 222, "production": 333 },
  "places": {
    "main": { "ci": 1001, "staging": 2001, "production": 3001 }
  }
}
```

An experience can stay `null` until it exists. With more places, each gets a line under `places`
with its id in all three experiences (`CLAUDE.md`, "To add a place").

Last, add a branch ruleset for `main` in the repo's settings that requires the `Checks` and `Specs`
status checks. Changes then reach `main`, and with it staging, only through a passing pull request.
GitHub offers rulesets on public repos, and on private repos with GitHub Pro, Team, or Enterprise Cloud.

## Publishing endpoint

Both publish and the test upload use the Place Publishing API,
`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions`, which returns
the new version number.

- Its permission, **universe-places**, can be restricted to the CI, staging, and production
  experiences. Roblox's place publishing guide now documents the Assets API's Update Asset
  instead, but that needs **assets**, whose Write reaches every asset the account can access.
- It saves an unpublished version (`versionType=Saved`) for the specs and publishes
  (`versionType=Published`) for staging and production, so one permission covers both.
- It accepts place files up to 10 MB.
- The scripts call it themselves rather than through `rojo upload`, which always publishes, so it
  can't save the unpublished version the specs run against. `rojo upload` also builds straight from
  the project, which would ship the specs and Jest to players.

## When a run fails

- **Specs fail with 429:** Luau Execution allows 5 task creates per minute per key owner and 10
  unfinished tasks per place, and each place creates one task. A 429 waits up to a minute, then
  retries. A long `retry-after` means an hourly
  lockout: rerun the job later. Use your own key, not the CI account's, for any Luau Execution you
  run by hand.
- **Specs end with `INTERNAL_ERROR`:** a Roblox-side failure. The script runs the task once more.
  If it fails again, rerun the job.
- **A spec passes in Studio and fails here:** CI runs specs on a game server, where
  `RunService:IsServer()` is true. In Studio's edit mode it's false.
- **Publishing fails with 409 "Server is busy":** someone has that place open in Studio or Team
  Create. Close it and rerun the job. Places publish one at a time, so the ones before it are
  already out: rerun soon, so every place runs the same code.
- **A job fails with a `places.json:` message:** the message names the entry or folder to fix.
  Every folder in `places/` with a `default.project.json` needs an entry, and once an
  experience's universe is set, every place needs its id there.
- **Specs fail with "ROBLOX_API_KEY is not set" on a pull request from a fork or Dependabot:**
  GitHub withholds secrets from those runs.
- **Specs fail with "ROBLOX_API_KEY has spaces, line breaks, or control characters inside it",
  or with "failed to parse header value" in an older copy of these scripts:** the secret holds
  more than the key, usually from pasting it into GitHub's web form. Store it again with
  `tools/set-api-key.ps1` or `tools/set-api-key.sh`.
