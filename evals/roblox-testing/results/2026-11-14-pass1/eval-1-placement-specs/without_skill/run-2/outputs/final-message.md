I added the specs in `src/ServerScriptService/Tests/Specs/PlacementRules.spec.luau`. luau-lsp, selene and `stylua --check` all pass on `src` with no errors or warnings. The specs haven't been run, since that needs Studio, and one of them is meant to fail until the bug below is fixed. I didn't touch `PlacementRules.luau` and didn't commit anything.

**Bug I found:** the doc comment on `validate` says "A cell exactly MaxReach away is in reach", but the code rejects with `(rootPosition - center).Magnitude >= PlacementRules.MaxReach`. It should be `>`. The spec "accepts a cell exactly MaxReach away" places the root exactly 24 studs straight above the cell, so there's no rounding error, and it will fail until that's fixed. I left a comment above it explaining why. Since the client preview and the server will share this rule, it's worth settling which way you want it.

**What the specs cover:**
- **`snap`:** a point anywhere inside a cell maps to that cell's center. A point on a boundary goes into the higher cell, negative coordinates round down, and each axis is snapped separately. Snapping twice gives the same result, and the cell resting on the Baseplate has its center at `BlockSize / 2`.
- **`validate`:** every block type in `BlockTypes.List` is accepted. Unknown names, wrong case and non-string names are rejected. Positions that aren't a Vector3 (nil, a string, a table, a CFrame, a Vector2) are rejected, as are NaN and ±infinity on each axis.
- **Height limits:** a position just below Y = 0 is rejected. Position Y = 199.9 snaps to center 198 and is accepted; Y = 200 snaps to 202 and is rejected.
- **Reach:** a missing character is rejected. Reach is measured to the cell center, not to the requested point, and it's straight-line distance across all three axes. There are cases just inside, exactly at, and just beyond `MaxReach`.
- **Occupied cells:** occupancy is looked up by the snapped center, a `false` entry counts as empty, and `occupied` is never changed. One spec checks that putting the returned center into `occupied` blocks a second placement in the same cell.
- **Check order:** block type is checked first, then position, then height, then character, then reach, then occupancy.

**Assumptions:**
- The reason strings (e.g. `"out of reach"`) are matched exactly, because they're the only way to tell which rule rejected a request. If you reword one, the spec needs updating too.
- Vector3 results are compared axis by axis, so a failure prints the numbers.
- Some coordinates are written out as numbers and assume `BlockSize` is 4, which it is now.
- The docs say a cell must be above the Baseplate (`Y > 0`) while the code checks `center.Y < 0`. These behave the same, because a cell center always sits halfway through a cell and so is never exactly 0. I didn't flag it as a bug.

One of my first commands, which tried to read several files and configs in one go, was blocked because it needed approval. I read the files individually instead, so nothing was skipped.