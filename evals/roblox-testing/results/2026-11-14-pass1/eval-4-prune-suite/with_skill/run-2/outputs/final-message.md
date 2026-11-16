I've cut `PlacementRules.spec.luau` from 31 tests to 20, and every rule PlacementRules documents is still covered. `PlacementRules.luau` is unchanged. I couldn't run the specs here, so the new suite hasn't run yet. luau-lsp, selene and StyLua all pass. Please run the spec in Studio or CI before merging.

**Why the two tests failed:**
- **"rejects a position that isn't a Vector3"** called `expect(ok):toBe(false)` with a colon. Jest Roblox matchers have to be called with a dot, so the test failed even though `validate` was correct.
- **"doesn't mark the cell occupied"** used `expect(0).toBeFalsy()`. In Luau only `false` and `nil` count as false, so `0` always failed. It now checks that the `occupied` table is still empty after an accepted request.

**Removed, because they broke on refactors or checked no rule:**
- The `_isFinite` tests (a private helper) and "calls snap exactly once" (an internal call count).
- A `snap` test that worked out its expected value with the same formula as `snap`, so it could never disagree with it.
- Repeated rows: one for each of the 5 block types (validate treats them all the same), and snap points that tested the same case.
- The `BlockTypes` test. It repeated colors and materials field by field and broke on every art tweak.
- Two tests that only passed because of what an earlier test left in a shared `occupied` table. Every test now builds its own table.

**Changed:**
- Refusal tests check only that the request is refused, not the reason text. The module documents the reason as a message for the server log, not part of the contract.
- Expected heights, reach distances and cell sizes now come from `MaxHeight`, `MaxReach` and `BlockSize`, so changing those values doesn't break the spec.
- The spec now follows the project's Luau style: `--!strict`, `const`, and string requires.

**Added:**
- "No character" (`rootPosition == nil`). This rule was documented but had no test.
- A block type that isn't a string, and an infinite position.
- A diagonal reach row, so reach is measured as a straight-line distance, as the docs describe.

**Assumption:** the doc comment says a cell must be at "Y > 0", but the code only rejects `Y < 0`. A cell's center can never be exactly 0, so the two always agree and I didn't add a test for it.

The note at `docs/placement-spec-cleanup.md` covers all of this and lists which test covers each rule. I haven't committed anything.