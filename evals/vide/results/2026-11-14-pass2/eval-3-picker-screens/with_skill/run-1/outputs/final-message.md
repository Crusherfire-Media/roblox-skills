The picker now has two layouts and switches between them live. It's built on a shared screen module that the next screens can use too. The type check, lint and format check all pass. I couldn't run any of it in Studio, so I haven't seen it on a real or emulated screen yet.

**How the picker behaves now**
- **Touch screens and small windows (phones, iPad, a laptop window dragged small):** the picker becomes a hotbar along the bottom of the screen. It's centered in the gap between Roblox's thumbstick area (the left 40% of the screen) and the jump button, so it's out of the thumbstick's way. Tiles are 52 px with no names beside them, and the selected block's name shows above the row. On a narrow phone the hotbar shrinks to fit, but never below 85%, so tiles stay at least 44 px, which is about the smallest a thumb hits reliably.
- **Desktop and laptop:** your original column on the left, at the same 1080p sizes you designed.
- **Big monitors:** the whole UI scales with the screen's height compared to 1080p. That's 1.33× on a 1440p monitor, 2× on 4K, a quarter more on a TV, and never larger than 3×. Phones and tablets stay at 1× and change layout instead. The title used to have a text size cap that wouldn't have grown on 4K, so I gave it a fixed size of 24.
- **Mid-session changes:** rotating, resizing the window, plugging in a keyboard and switching devices all update the picker immediately. It switches to the hotbar when Roblox's primary input is touch, or when the screen's short side is under 600.

**What the next screens can use**
- `UI/Screen.luau` keeps the facts about the screen as live values: screen size, the space below the topbar, touch or not, phone-sized or not, the overall scale, the free space between the touch controls, and a helper that shrinks a panel to fit.
- `UI/scaledScreenGui.luau` builds a ScreenGui with the big-monitor scaling already attached. Build each new screen with it and none of them need their own scaling code.
- `BlockPicker` takes its layout (`"Column"` or `"Row"`) as a setting and no longer decides where it sits. `Main.client.luau` picks the layout and position. `BlockPicker.designSize` gives the picker's size without measuring it on screen.

**Stories**
I added `ServerScriptService/Stories/BlockPicker.story` and a storybook. Its controls switch between the two layouts, set the number of block types (1–12), and turn on long names. UI Labs's helper package isn't installed, so the controls are plain values and won't keep a fixed order in the panel. Adding `ui-labs` to `pesde.toml` would fix that.

**Please check in Studio's Device Emulator**
- **Small phone (667×375):** the hotbar should sit between the thumbstick area and the jump button, at about 90% size.
- **iPad:** the hotbar at full size. With a keyboard connected, the column should come back.
- **1080p:** this should look the same as before.
- **4K (add it as a custom device):** the column at twice the size.
- **Switching devices during a playtest:** the picker should switch layouts cleanly, with no mix of the two.
- Check that tapping a tile on a phone doesn't start the thumbstick.

**Things to know**
- The touch-control positions are the default numbers for Roblox's own controls. If the game customizes them, or Roblox changes its layout, the gap will be off.
- On very small phones (568×320) the hotbar overlaps the thumbstick area and the jump button by about 6 px each, because it stops shrinking at 85%. Past about 7 block types it won't fit between the controls at all, so it will need scrolling or a second row.
- Phones held upright weren't considered.
- The scaling numbers (never below 1×, at most 3×, the TV boost) are a starting point I chose. They're easy to change if 4K looks too big or too small.
- I followed the project's existing code style (`local`, `require(script.Parent...)`, module tables named after their files) rather than a newer style, so the files stay consistent.
- I didn't move `BlockPicker` into `UI/`, because I couldn't delete files from here.
- Consider adding `Vide.strict = RunService:IsStudio()` in `Main.client.luau`; it makes Vide catch more mistakes while you develop.
- `sourcemap.json` was regenerated. Nothing is committed.