I've written the module and checked the formatting by hand. Here's what it does and what I couldn't run.

I created `src/ReplicatedStorage/Shared/PlacementRules.luau`. **It hasn't been run or analyzed.** My shell commands were blocked because this session can't approve them, so StyLua, Selene and a type check never ran. I followed your `stylua.toml` by hand. A quick Studio test, or a StyLua and analyzer pass, is still needed.

**What it exposes**
- **`BlockTypes`**: the five types (`Brick`, `Dirt`, `Grass`, `Window`, `Wood`) as a list the picker UI can loop over, plus `BlockSize` (4). It also exports the `BlockType` type.
- **`isBlockType(value)`**: returns false for anything that isn't one of those five strings, including other kinds of value.
- **`snapPosition(position, baseplate)`**: returns the center of the 4-stud grid cell that contains `position`. The vertical grid starts at the Baseplate's top surface, so the lowest layer of blocks rests on it. Horizontally, cells line up on multiples of 4, which also matches the Baseplate's edges.
- **`validate(player, blockType, position, context)`**: returns either `{ Ok = true, BlockType, Position }` or `{ Ok = false, Reason }`. `context` is `{ Baseplate = ..., BlocksFolder = ... }`. On success, `Position` is the snapped cell center, so place the block there rather than at what the client sent.

**Failure reasons** (short strings for your server log): `InvalidBlockType`, `InvalidPosition`, `TooLow`, `TooHigh`, `NoCharacter`, `TooFar`, `Overlapping`.

**Things to know when you wire it up**
- **The server snaps whatever the client sends.** An unsnapped position isn't rejected; it's snapped and then checked. Both sides go through the same snapping, so they always agree.
- **Bad input doesn't error.** Anything that isn't a `Vector3`, or has a NaN or infinite component, comes back as `InvalidPosition`. Very large but finite numbers fail the height or distance check before the overlap query runs.
- **Height:** the block's bottom can't be below the Baseplate's top, and its top can't be more than 200 studs above it. That allows 50 layers.
- **Reach:** distance is measured from the HumanoidRootPart to the block's center. If the player has no character yet, the result is `NoCharacter`.
- **Overlap** uses `GetPartBoundsInBox` with a box 0.1 studs smaller than a block, so blocks touching face to face are fine. Every placed block must be a `BasePart` inside the folder, with `CanQuery` left on.
- **Keep the client's ghost preview out of `BlocksFolder`**, or every preview will count as overlapping itself.
- **For the client preview**, push the raycast hit point slightly off the surface before snapping, e.g. `result.Position + result.Normal * 0.5`. Otherwise, clicking the side of a block snaps into that block instead of next to it.
- **I pass the Baseplate in rather than looking it up by name inside the module.** If streaming is enabled, it may not be loaded on the client yet, so the caller decides how to find it.

I haven't committed anything.