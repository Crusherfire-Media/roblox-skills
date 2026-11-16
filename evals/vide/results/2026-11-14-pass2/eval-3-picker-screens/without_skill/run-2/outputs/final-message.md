The picker now adjusts to the device and the input the player is using, and it changes live when they rotate, resize the window or switch input. The type checker, selene and stylua all pass, but **I haven't run it in Studio or on any device**, so the sizes and positions below are reasoned out, not seen. I haven't committed anything.

**Shared setup for this and future screens (`StarterPlayerScripts/UI/`)**
- **`Screen.luau`**: wrap every screen in this. It keeps content clear of the Roblox top bar and phone notches, and measures the space that's left.
- **Scaling:** you keep sizing things in "design units", where 1 unit is 1 pixel on your 1080p monitor. Phones, tablets, laptops and 1080p stay at 1×. Bigger screens scale up to match: about 1.35× at 1440p and 2× at 4K. That fixes the "tiny on 4K" problem without shrinking anything on small screens.
- **`Responsive.luau`**: inside a screen, `Responsive.use()` gives live values for the usable size, the scale, a size class (phone / tablet or small laptop / desktop), portrait vs landscape, and the input in use (touch, keyboard and mouse, or gamepad). The input comes from Roblox's built-in "preferred input" setting, so plugging in a keyboard or touching the screen switches it.
- I added a short UI section to the README describing this.

**Block picker (`BlockPicker.luau`)**
- **Keyboard/mouse or gamepad on a big enough screen:** same column as before, on the left with names beside the tiles. With a keyboard it now also shows the 1–5 hotkey on each tile.
- **Touch, or any screen too small for the column:** it becomes a bar across the top centre, away from the thumbstick and jump button in the bottom corners. Tiles grow from 40 to 48 with wider gaps, so they're easier to hit. Names are hidden there, but the title still shows the selected block.
- The yellow selection border is now drawn as a slightly larger tile behind each colour square, so I know it scales with the rest of the UI. I wasn't sure Roblox's built-in border style would.

`Main.client.luau` now mounts the picker through `Screen`.

**Worth checking in Studio's device emulator:** a phone in portrait and landscape, an iPad, and a large window. If you add more block types, the top bar will eventually be too wide for a phone in portrait (5 fit now). The fix would be to shrink or wrap the tiles.

**Two commands were blocked** because this session can't approve permission prompts:
- An early shell command to list the project files. I used file search instead.
- Running stylua to rewrite files. It wanted to re-wrap one line, so I made that edit by hand and the check now passes.