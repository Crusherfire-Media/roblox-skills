I added `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and StyLua all pass on it, and I didn't touch `PlacementRules.luau`. The specs haven't been run, because Jest only runs in Studio. I worked out by hand which tests should pass, but nothing has confirmed it.

**Bug found (that test should fail):** "accepts a cell exactly MaxReach from the character". The doc comment on `validate` says a cell exactly `MaxReach` away is in reach. But the code checks `(rootPosition - center).Magnitude >= PlacementRules.MaxReach`, so it refuses that cell. The fix would be to use `>`, or to change the doc if refusing is what you want. The comment above the test explains this.

**What the specs cover** (10 `it` blocks, 22 cases):
- **`snap`:** a position inside a cell, negative coordinates, and a position exactly on a cell edge, which belongs to the cell above.
- **Accepted placement:** returns the snapped center, and every block type in `BlockTypes` is accepted.
- **Bad input:** a block type name that isn't a string, an unknown block type, a position that isn't a Vector3, and NaN, +inf and −inf positions are all refused.
- **Height:** the cells just above and just below the top of the Baseplate, and just above and just below `MaxHeight`.
- **Reach:** no character is refused; just inside and just past `MaxReach` are checked, plus the failing exact-`MaxReach` test.
- **Occupied cells:** a position whose own cell is taken is refused, a free cell next to a taken one is accepted, and `validate` never changes `occupied`.

**Assumptions:**
- **Your settings can change:** positions are given in block-size units and limits are read from `PlacementRules.MaxHeight`, `MaxReach` and `BlockTypes.BlockSize`. Changing those values shouldn't break the tests.
- **Reason strings aren't checked:** tests only check accepted or refused, so rewording a log message won't break anything. Each refusal test is set up so it can only fail the rule it's testing.
- **Vector3 lookup:** the occupied tests rely on a table keyed by Vector3 finding the same coordinates, which is how Luau vectors behave.

**One mismatch with no effect:** the doc says the cell's center must be above the Baseplate (Y > 0), but the code refuses only Y < 0. A snapped center can never be exactly 0, so this doesn't change any result, and I didn't write a test for it.

**Next step:** run the new spec in Studio. Expect 21 passes and 1 failure, the exact-`MaxReach` test. Nothing is committed.