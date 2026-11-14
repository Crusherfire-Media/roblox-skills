I've added the three animations using Vide springs. I couldn't test any of it: commands need approval and this session can't grant it, so I couldn't run a linter, type checker or Studio. Check it in a playtest before relying on it.

**Slide in and out** (`BlockPicker.luau`, `Main.client.luau`)
- The picker now takes an `Open` value. `Main.client.luau` passes it build mode instead of wrapping the picker in `show`.
- One spring moves the panel between its normal spot and just below the bottom of the screen. It's a little bouncy on the way up.
- The panel stays on screen while build mode is on, or while it's still sliding down. It's removed only once the spring has come to rest out of view, so it always finishes sliding down before it goes away.
- **Spamming B or the Build button:** the slide spring sits outside the part that gets added and removed, so it doesn't start over on each press. Pressing B halfway through a slide just turns the motion around from wherever the panel is. The panel isn't rebuilt and nothing jumps. While the panel is sliding away, its tiles ignore presses.

**Gliding highlight**
- The yellow outline on each tile is gone. Instead there's one yellow ring that springs sideways to the selected tile. It sits 4px outside the tile so it still looks right when the tile shrinks under a press.
- It also glides when you change blocks with the number keys 1–5. When the picker opens, the ring starts on the current block instead of gliding in.
- Each tile keeps its thin grey border.

**Tile press**
- Each tile sits inside a fixed-size slot, so the layout never shifts. When you press a tile it shrinks to 0.88 from its centre, and when you let go it bounces back.
- A press is released when you lift the mouse button or finger, or when the pointer leaves the tile, so a tile shouldn't get stuck shrunk.

**One thing about Vide's springs:** a spring aimed at exactly 0 takes a very long time to fully stop. Because of that, every animated value has a resting point that isn't 0, which lets the slide-out end cleanly and remove the panel.

The timings (period and bounciness for slide, glide and press) are constants at the top of `BlockPicker.luau` if you want to tune them.