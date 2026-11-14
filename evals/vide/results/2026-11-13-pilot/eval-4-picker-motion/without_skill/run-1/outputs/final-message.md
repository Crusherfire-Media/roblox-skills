I've added all three animations, but none of it has been run or checked. My shell commands were blocked by the permission system, so I couldn't run a type checker, linter or Studio. Please try it in Studio before relying on it.

**What changed**

- **Slide in and out** (`BlockPicker.luau`, `Main.client.luau`): the picker's position now animates with a Vide spring. When build mode turns on, it starts just below the screen and slides up with a small overshoot. When build mode turns off, it slides back down. The picker reports how long that slide takes (0.35s), and Vide's `show` waits that long before removing it.
- **Gliding highlight**: the outline on each tile is replaced by one yellow highlight frame that springs to the selected tile. When the picker opens, the highlight starts on the current block rather than gliding in from the first tile. To make this work I moved the row of tiles into an inner `Tiles` frame, so the highlight can sit above them and move freely.
- **Tile reactions**: tiles grow slightly (1.06×) on hover, shrink (0.88×) while held, and bounce back when released. This works for mouse and touch. I turned off Roblox's built-in button darkening so the two effects don't stack. Each tile is now a plain frame named after its block, with the actual button inside it (named `Button`). The button has to sit inside a frame so it can be centred and shrink from the middle instead of the top-left corner.

**Spamming B or the Build button**

If you toggle again while the picker is sliding out, Vide cancels the removal and the same picker springs back up from wherever it is. If you toggle off while it's sliding in, it reverses smoothly. Only one picker exists at a time. Tiles also ignore clicks while the picker is sliding out, so you can't pick a block from a picker that's leaving.

**Tuning**

The timings are constants at the top of `BlockPicker.luau` (`SLIDE_*`, `GLIDE_*`, `PRESS_*`, `EXIT_DURATION`). If you make the slide slower, raise `EXIT_DURATION` to match, or the picker will disappear before it's fully off screen.