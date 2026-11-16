The selected block type is now a Charm signal owned by `BlockPlacer`, and `BlockTypeChanged` is gone. I haven't tested this: the session couldn't run tool commands, so I didn't run Luau type-checking, a linter, or Studio. The parts to check in a playtest are number keys 1–5, tile clicks, the yellow outline and the ghost block's color.

**`BlockPlacer.luau`**
- The plain local and the `BindableEvent` are replaced by `Charm.signal`.
- The read side is exposed as `BlockPlacer.selectedBlockType`, which replaces `getBlockType`. Nothing else used `getBlockType`.
- Writes still go through `BlockPlacer.setBlockType`, so the unknown-name check stays in one place. I removed the manual "same value, do nothing" check because Charm's setter already skips unchanged values.
- Number keys still call `setBlockType`, and placing a block reads the current value from the signal.

**`PlacementPreview.luau`**
- The initial `applyBlockType` call and the event connection are replaced by a single `Charm.effect`. It colors the ghost once at start and again whenever the selection changes.

**`Main.client.luau`**
- The copied Vide source and its event listener are removed. The hotbar now gets `Selected = BlockPlacer.selectedBlockType` directly. Clicking a tile still calls `BlockPlacer.setBlockType`.

**`BlockPicker.luau`**
- `props.Selected` is now a Charm signal. The component turns it into a Vide value once with `VideCharm.useSignalState(props.Selected)`, and every tile's outline reads from that. This step is needed because Vide doesn't update when you read a Charm signal directly.
- `BlockPicker` still gets its state through props rather than requiring `BlockPlacer`, so it stays separate from game logic and is easy to preview (for example, as a UI Labs story).

The placing on/off flag (`isEnabled`) is still a plain local because it was outside this task. It's the obvious next thing to move to Charm.