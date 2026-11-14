The picker now changes layout to fit the screen, and it keeps changing as the screen does. The type check, lint and format check all pass, but **I haven't run it in Studio**, so none of the layout has been seen on a real or emulated screen yet. Nothing is committed.

**How it behaves**
- **Phones, and tablets used by touch:** the picker becomes a row along the bottom. It sits between the area where the thumbstick appears (the left 40% of the screen) and the jump button. Tiles are 56 px where there's room and shrink to no less than 44 px, which is about the smallest a thumb hits reliably. If the strip between the controls is too narrow even at 44 px, the tiles wrap onto a second row so they never reach either control.
- **Laptops, 1080p monitors, and tablets with a keyboard connected:** the same column on the left edge as before. Tiles went from 40 to 44 px so they're still easy to hit when a tablet player taps the screen.
- **1440p and 4K:** the whole UI grows with the screen height. It's 1.33× at 1440p, 2× at 4K, and capped at 3×. The title used to stay small at 4K, so it now uses a fixed text size that grows with everything else.
- **Changes mid-session:** rotating, resizing the window, or connecting or disconnecting a keyboard, mouse or gamepad all move the picker straight away. A desktop window dragged down to phone size switches to the row too.
- **Gaps between tiles:** taps there used to fall through and place a block in the world. The panel now catches them. That relies on how Roblox handles input, so please confirm it in a playtest.

**For future screens**
- **`Screen.luau`:** one shared module that tracks the screen size, the Roblox top-bar height, whether touch is the main input, and whether the screen counts as phone-sized. It also gives the strip of the bottom edge that the touch controls leave free.
- **`GameScreenGui.luau`:** the wrapper every screen should be built in. It holds the single scale-up setting, so no screen does its own scaling.
- **`BlockPicker.luau` / `BlockPickerScreen.luau`:** the picker takes its layout as a setting, and the screen file decides which layout and where it goes. Copy that split for new screens.

I also turned on Vide's strict mode in Studio, which catches common UI mistakes during development.

**Please check in Studio's Device Emulator**
1. A small phone (667×375) and a smaller one (about 568×320). The row should stay clear of the thumbstick area and the jump button, and wrap on the smaller one.
2. A tablet, then switch the device during the playtest. The picker should move cleanly between the two layouts.
3. 1080p, then custom 1440p and 4K devices. It should look the same as now, just bigger.
4. Tap the gaps between tiles and confirm no block gets placed.

**Still open**
- **Tile colors:** the row hides block names, and Brick, Dirt and Wood are three similar browns. Touch players, especially colorblind ones, can only tell them apart by tapping and reading the title. Short labels or material textures on the tiles would fix it; which you prefer is your call.
- **Not covered:**
  - phones held upright, which squeeze the row hard;
  - picking blocks with a gamepad;
  - the player's text size setting;
  - adding many more block types, which would need scrolling.
- **No previews:** UI Labs isn't installed in the project, so there are no stories. If you add it, `Screen` needs a small addition so stories can pretend to be a phone or a 4K screen.
- **Code style:** I kept the project's existing style (`local`, `require(script.Parent.X)`, no file headers), not the Luau style guide.