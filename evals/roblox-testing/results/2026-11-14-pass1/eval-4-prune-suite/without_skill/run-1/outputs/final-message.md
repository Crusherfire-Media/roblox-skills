I've cleaned up `PlacementRules.spec.luau` and written the PR note at `docs/placement-spec-cleanup.md`. luau-lsp, selene and StyLua all pass. The specs themselves haven't been run, since they can't run here. `PlacementRules.luau` is unchanged, and nothing is committed.

**Why the two tests failed (both were problems in the tests, not in placement):**
- **"rejects a position that isn't a Vector3"** called `expect(ok):toBe(false)` with a colon. Jest matchers need a dot; with a colon the matcher compares against the wrong value, so the test fails even when `validate` is right.
- **"doesn't mark the cell occupied"** checked that an entry count was falsy. In Lua, `0` counts as true, so the test failed exactly when the code was correct. It now checks that the caller's table is unchanged.

**Removed (7):**
- The `snap` test that worked out the expected answer with the same formula the module uses, so it could never catch a wrong formula.
- The three `_isFinite` tests, which tested a private helper. NaN and infinity are now tested through `validate`.
- "calls snap exactly once", which checked how `validate` is built rather than what it returns.
- "rejects placing twice", which only passed because an earlier test had filled in a shared `occupied` table.
- The `BlockTypes` colours-and-materials test, which belongs to a different module.

**Fixed:**
- Every test now builds its own `occupied` table, so tests can run in any order or one at a time.
- "Returns the snapped center" compares against a fixed value instead of calling `snap`.
- Rejection tests now check the reason, so they confirm which rule did the rejecting.

**Added (9) for rules that weren't covered:**
- A player with no character is rejected. Nothing tested this before.
- Positive and negative infinity are rejected (only NaN was tested before).
- Block types that aren't strings (nil, a number, a table) are rejected.
- A free cell next to an occupied one is accepted.
- One more `snap` case, moved from the deleted test with a worked-out answer.
- A check that block size, max height and max reach are still 4, 200 and 24.

That takes the suite from 31 tests to 33. The note has a table mapping each rule in `PlacementRules` to its tests.

**Calls I made (also in the note):**
- **Fixed numbers:** the edge cases use the current block size, max height and reach. The check on those three values fails first, with a clear message, if any of them is changed.
- **Reason text is checked:** rewording a server-log reason will mean updating the matching test. I kept the checks because otherwise a rejection test can pass when the wrong rule rejected the request.
- **Small doc/code mismatch:** the module's comment says the cell's center must be above 0, but the code only rejects below 0. A cell center can never be exactly 0, so they behave the same and I left it alone.

Two of my shell commands were blocked by the permission system: one that printed files, and one that ran several checks at once. I read the files with the file viewer and ran each check as its own command instead, so nothing was skipped.