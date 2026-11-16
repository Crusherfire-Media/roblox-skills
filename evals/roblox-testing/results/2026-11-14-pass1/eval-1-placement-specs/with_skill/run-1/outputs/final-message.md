I've written the specs in `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and `stylua --check` all pass on `src`. As expected, nothing has run in Studio, and `PlacementRules.luau` is unchanged.

**One test should fail: `PlacementRules validate accepts a cell exactly MaxReach away`.** The doc comment on `validate` says a cell exactly `MaxReach` away is in reach. But the code checks `>= MaxReach` (line 72), so it refuses that cell. I assumed the doc is what you meant and wrote the test to match; the comment above the test says so. If the code is actually right, change the doc comment and flip the test.

**What the specs cover** (10 tests, 1 red):
- **`snap`:** one table covering a position inside a cell, on the origin, just below a cell's upper edge, on a cell edge (it goes to the upper cell), just below zero, and mixed axes.
- **Accepted placement:** returns the cell's center and leaves `occupied` unchanged.
- **Every block type in `BlockTypes` can be placed:** if any are refused, the failure lists them all.
- **Unknown block types are refused:** a non-string, and a name that isn't in `BlockTypes`.
- **Bad positions are refused:** a table shaped like a Vector3, NaN, +inf and −inf.
- **Height:** below the Baseplate (refused), resting on it (accepted), the highest cell at or under `MaxHeight` (accepted), and the cell above it (refused).
- **No character:** refused.
- **Reach:** just inside (accepted), just outside (refused), and diagonal. The diagonal case is inside the limit on each axis but too far in a straight line, so it's refused; this shows reach is measured as straight-line distance.
- **Occupied cells:** a different position inside an occupied cell is refused; the cell next to it is accepted.

**Assumptions:**
- Expected values are written as multiples of `BlockTypes.BlockSize`, and `MaxHeight` and `MaxReach` are read from the module, so changing those numbers won't break the tests. The highest allowed cell is found by counting cells upward rather than by copying `snap`'s formula.
- Tests check only the true/false result, not the reason string, so rewording a message won't break them. Each refusal test makes every other input valid.
- I assumed Jest's `toEqual` compares Vector3s by value, and that `occupied` looks up Vector3 keys by value (Luau's native vector type). If either is wrong, it will show up on the first Studio run.
- The testing skill says to agree the list of behaviors first and to try breaking each test against the code. You couldn't be asked, and the specs can't run here, so I chose the list myself and skipped the break-it check.

**Two things I didn't test:**
- The doc says the cell's center must be at Y > 0, but the code rejects only Y < 0. You can't see the difference, because a cell center is never exactly 0.
- If `rootPosition` has a NaN component, the distance is NaN, `NaN >= MaxReach` is false, and the reach check passes. `rootPosition` comes from the server, not from the client, so this isn't a documented rule being broken. You may still want reach to refuse in that case.

Running the rojo sourcemap step created `sourcemap.json`; git ignores it, so the spec is the only new file in the working tree. Nothing is committed.