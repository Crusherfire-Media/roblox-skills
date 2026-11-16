I've added the specs in `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and `stylua --check` all pass on `src` with no errors or warnings. I couldn't run the specs, because they only run in Studio. I didn't touch `PlacementRules.luau`, and the spec file is the only change.

**One test should fail: I think the code has a bug.** `validate`'s doc comment says "A cell exactly MaxReach away is in reach." But the code checks `Magnitude >= PlacementRules.MaxReach`, so a cell exactly 24 studs away is rejected. The test "accepts a cell exactly MaxReach away" follows the doc comment. I picked a distance that is exactly 24 with no rounding, so the failure is real. The comment above the test explains the problem. The fix is either to change `>=` to `>`, or, if rejecting is what you want, to change the doc comment and this test. This matters for the client preview: a player standing exactly 24 studs away would get a result that contradicts the documented rule.

**What the specs cover:**
- **`snap`:** the origin cell, points inside a cell, points on and just below a cell's edge, negative coordinates, each axis snapping separately, and snapping twice giving the same result.
- **Block type:** every entry in `BlockTypes.List` is accepted. Unknown names, the empty string, lowercase names, and values that aren't strings (nil, a number, a boolean, a table) are rejected without erroring.
- **Position:** the snapped cell center is returned. Values that aren't a Vector3 (a table shaped like one, a CFrame, a Vector2, a Vector3int16, and others) are rejected. NaN, infinity and negative infinity are rejected on each axis.
- **Height:** the cell resting on the Baseplate is accepted, cells inside or below the Baseplate are rejected, and the highest cell within `MaxHeight` is accepted while the one above it is rejected.
- **Reach:** a player with no character is rejected. Distances just inside and just beyond reach behave correctly. Distance is measured in 3D and from the cell's center, not from the requested point.
- **Occupied cells:** a taken cell is rejected for any point inside it, and the lookup matches even when the stored key was built separately. Neighbouring cells are still accepted. `occupied` is never changed: most tests pass a frozen table, so any write would error.

**Assumptions:**
- Rejection reasons are compared word for word, so each test proves the intended rule did the rejecting. If you reword them, update the `REASONS` table at the top of the spec.
- Positions are calculated from `BlockSize`, `MaxHeight` and `MaxReach` rather than typed in, so the tests keep working if those values change.

**Another mismatch, not tested:** the doc comment says a cell's center must be above the Baseplate (Y > 0), but the code checks `center.Y < 0`. With a cell size of 4, no cell center can be exactly 0, so the two behave the same today and no test can catch it. It could start to matter if the grid changes.