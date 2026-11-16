I've rewritten the spec and added the PR note at `docs/placement-spec-cleanup.md`. luau-lsp, selene and StyLua all pass on it. The specs haven't been run, since that needs Studio, and `PlacementRules.luau` is unchanged. Nothing is committed yet.

**Why the two tests failed:**
- **"rejects a position that isn't a Vector3"** called `expect(ok):toBe(false)` with a colon instead of a dot. That compared `false` against the expectation table, so the test could never pass. luau-lsp doesn't flag it, which is probably why nobody spotted it.
- **"doesn't mark the cell occupied"** asserted `expect(0).toBeFalsy()`, but in Luau `0` counts as true. It now checks that the table is still empty, on both the accept and reject paths.

**What I removed:**
- **The test that spied on `snap` being called exactly once.** It checked how the code works, not what it does, so refactors broke it.
- **The 3 tests of the private `_isFinite` helper.** I replaced them with `validate` cases using NaN, infinity and negative infinity. Before, only NaN was tested through `validate`.
- **The test that worked out its expected values with the same formula as the code,** so it could never fail.
- **The `BlockTypes` colours/materials test.** That's game content, not a placement rule, so any content tweak broke it.
- **"rejects placing twice in the same cell".** It repeated the occupied test and only passed because an earlier test had filled a shared table. Each test now builds its own data.

**What I changed:**
- **No exact reason messages.** The module only promises "a short reason", so a rejection now just has to return `false` and some non-empty message. To be sure each rejection comes from the rule being tested, every case takes a request that passes and changes one input.
- **Limits read from the module.** Height and reach tests use `MaxHeight`, `MaxReach` and `BlockSize` instead of hard-coded 200, 24 and 4, so retuning those numbers won't break them.
- **New tests:** a player with no character (wasn't tested before), a placement past reach diagonally even though each axis is within range, and a free cell next to an occupied one.

The note includes a table mapping each documented rule to the tests that cover it. The suite still has 31 tests; the difference is that each one now checks a documented rule.

**Assumptions** (also in the note):
- The module's comment says a cell must be at "Y > 0", but the code rejects `Y < 0`. The two behave the same, because a cell's centre can never be exactly 0. So I tested the cells on either side of the boundary rather than Y = 0 itself.
- `_isFinite` is still exported from `PlacementRules.luau` because I wasn't allowed to change that file. Nothing tests it now, so the export can be removed in a later change.