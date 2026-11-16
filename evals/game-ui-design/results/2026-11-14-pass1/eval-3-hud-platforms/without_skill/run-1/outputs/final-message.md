The HUD now changes its layout and prompts whenever the player switches input, and keyboard-and-mouse looks the same as before. Static checks pass (luau-lsp shows no type errors, selene shows no warnings, stylua is clean). I haven't run it in Studio or on a real phone, tablet, Xbox or controller, so none of the layouts or bindings have been seen working yet. Nothing is committed.

**How switching works:** a new `InputMode.luau` follows Roblox's `UserInputService.PreferredInput`, which Roblox updates as the player changes input mid-session. It also ignores noise like phone gyro readings that would otherwise make the HUD flicker between modes. The HUD redraws its prompts every time that value changes.

**Keyboard and mouse:** same layout, sizes, number keys on slots, hover tooltip, `[B]` hint and `[I] Inventory` button as before. Two small internal changes:
- Buttons now use `Activated`, which behaves like a mouse click on PC but also responds to taps and controllers.
- Buttons are marked non-selectable, so controller menu navigation can't wander into the HUD.

**Touch:**
- Slots grow from 40 to 48px so they're easier to tap.
- On small phones, if the 10 slots don't fit between the thumbstick and jump button, the hotbar wraps to two rows of 5.
- The name of the selected block shows above the hotbar instead of a hover tooltip, since touch has no hover.
- Tappable **Build: ON/OFF** and **Inventory** buttons sit in the top right under the coins. Before this, a phone player had no way to turn build mode on or off.
- Hover is only recorded in keyboard-and-mouse mode. Touch fires a hover on tap but never ends it, which would have left tooltips stuck on screen.

**Controller:**
- LB/RB switch to the previous/next block (wrapping at the ends), X turns build mode on or off, Y opens the inventory.
- The prompts use the real button images for the connected controller (Xbox or PlayStation), with a text fallback.
- The selected block's name shows above the hotbar.
- The HUD is scaled 1.2× for a controller on PC, and 1.5× on consoles with a wider gap from the screen edge because TVs can cut off the edges of the picture.
- The bindings take priority over Roblox's defaults and stop the press there. Roblox's backpack also uses the bumpers.

**Files:**
- New: `Controls.luau` holds every key and button binding in one place. Main uses it to bind them and the HUD uses it for its labels, so changing a binding updates both.
- New: `InputMode.luau`.
- Changed: `UI/Hud.luau`, `Main.client.luau`.

**Decisions for you:**
- **Controller buttons:** I picked them to stay off A (jump), the sticks, Select/View (Roblox uses it for menu navigation), Start (Roblox menu) and the triggers, which I left for the placement dev. Please check with them that X, Y, LB and RB don't clash with their plans. X is also Roblox's default button for proximity prompts, if you ever add those. Changing any of these is a one-line edit in `Controls.luau`.
- **Touch layout:** where the hotbar wraps depends on hardcoded estimates of where Roblox puts its thumbstick and jump button (`SMALL_TOUCH_SCREEN`, `TOUCH_CONTROLS_RESERVE` in `Hud.luau`). Check on a small phone, such as an iPhone SE in landscape, and on a tablet.
- **Controller on PC:** a PC hooked up to a TV can't be detected, so it gets the 1.2× size rather than 1.5×. Change `GAMEPAD_SCALE` if your couch players need it bigger.