# roblox-testing evals (M12)

Four tasks and a trigger set for the `roblox-testing` skill. Specs can't run in trials (no
Studio), so every task is judged from the diff plus `luau-lsp`, `selene`, and StyLua. Fixtures
are in `tasks/fixtures/`; `shared/BlockTypes.luau` is the five block types from the vide evals.
How to run them is in `../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `placement-specs` | Writing specs for an untested rule module (`PlacementRules.validate` and `snap`): Jest Roblox API (JestGlobals, dot matchers, `.never`), one test per documented rule, both sides of each boundary, hand-worked expected values, no shared state. A planted bug (`>= MaxReach` where the doc says a cell exactly MaxReach away is in reach) should come out as a red test with a comment, since the prompt forbids editing the module. |
| `fix-inventory` | A bug report with a regression test. `BlockInventory.take` skips its amount check when a type has no entry, so new players can place one Window and drop to -1. The fix belongs in `take`; the test has to use a type the inventory never held, because a type stored at 0 was already refused. |
| `ci-runner` | The CI path: a workflow plus the Luau task script for Open Cloud Luau Execution. Judged on `error()` when Jest reports failures, one task pinned to the uploaded version, polling with a deadline, a concurrency group and 429 handling, `LoadStringEnabled` in the CI build, and secrets. |
| `prune-suite` | Pruning a 31-test spec: delete tests coupled to internals (`_isFinite`, a spy on `snap`), tautologies, and a catalog restatement; merge rows that are one case; fix two tests that fail for Jest Roblox reasons (colon matcher calls, `toBeFalsy` on 0); remove a test that depends on another test's leftovers; add the missing no-character test; write a PR note. |

Checks confirm files exist, planted patterns are gone, and the module under test is unchanged
(`git diff --quiet HEAD -- <file>`). Each check was run on the untouched starting point (it fails
where the task needs work) and on a hand-made correct answer (it passes).

## Judge facts

All Jest facts were checked against `test_packages/roblox_packages/.pesde` in sandbox-v2, and
each names its source file: no injected test globals, dot matchers and `.never`, `toBe`/`toEqual`
on Vector3, specs need no `return`, keyed `it.each` rows, `toBeFalsy` on 0, the `runCLI` result
shape, and Jest's `loadstring` fallback. `ci-runner` also carries one fact from Roblox's Open Cloud
reference (task states, `SCRIPT_ERROR`, rate limits, timeout, log cap), because the correct
workflow depends on it and the judge can't look it up.

**"There are no test globals" (jest-api.md) is correct for Jest Roblox 3.21.0.** `injectGlobals`
defaults to true (`jest-config/src/Defaults.lua`), but it only copies the globals into
`environment.global` (`jest-circus/.../jestAdapterInit.lua`, line 177). `jest-runtime/src/init.lua`
builds each module's environment from the loaded chunk's own environment (lines 1940 to 2021) and
never reads `environment.global`; every line in the runtime that would read it is commented out.
So a spec that calls bare `describe` fails, and luau-lsp and selene flag it as an unknown global.

## Notes

- The skill's loop asks the agent to confirm the behavior list with the user before writing any
  spec. Trials are headless, so a with-skill agent that stops to ask produces nothing. The prompts
  don't mention it; watch for trials that end with a question instead of a diff.
- `triggers.json` holds 10 queries that should load the skill and 10 near misses: JS Jest,
  playtests, TestEZ, profiling, a lint-only CI workflow, UI Labs stories, a rename, pytest, remote
  validation, and a luau-lsp type error. TestEZ is labeled false because the description is about
  Jest Roblox only.
