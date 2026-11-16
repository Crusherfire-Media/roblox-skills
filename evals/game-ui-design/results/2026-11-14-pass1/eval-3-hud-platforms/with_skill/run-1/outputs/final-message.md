The HUD now has three layouts (desktop, touch, controller/TV) and switches between them live as the player changes input. The type check, lint and formatting all pass, but nothing has been run in Studio yet: I couldn't connect to it from here, so there's no playtest, no story run and no device-emulator screenshots. Nothing is committed.

**How it switches.** A new `UI/Screen.luau` tracks the screen size, the player's current input (Roblox's `PreferredInput`), whether it's a TV, and the background transparency setting. All of these update during a session. If someone picks up a controller on PC, the HUD changes to the controller layout immediately, and switches back when they use the mouse again.

**Desktop:** looks and behaves as before. The `[B]`/`[I]` hints, number keys, sizes and positions are unchanged. Three small changes:
- The block name now always shows above the hotbar instead of only on hover. Colour alone doesn't tell Ice from Window, and touch and controller have no hover.
- The build mode hint can now be clicked.
- If the window is too narrow for one row, the hotbar wraps to two rows instead of overlapping the corner buttons.

**Touch:**
- Hotbar slots are bigger (48 instead of 40). The hotbar sits in the gap between the thumbstick area (left 40% of the screen) and the jump button. It's one row if it fits, otherwise two rows of 5.
- Build mode and Inventory become 96×56 tap buttons stacked above the jump button. Both bottom corners belonged to the player's thumbs before.
- Number key labels are hidden.

**Controller / TV:**
- **Buttons:**
  - LB/RB: cycle blocks
  - Y: build mode
  - X: inventory
- Button pictures come from Roblox (`GetImageForKeyCode`), so they're correct for Xbox and PlayStation pads.
- Text and slots are bigger, everything stays 5% in from the screen edges (some TVs cut off the edges), and the whole UI is scaled up 1.25× on TVs.

**Fixes that apply to every input:**
- Buttons use `Activated`, so they work with mouse, touch and controller.
- The whole HUD scales with screen size (1× at 1080p, about 2× at 4K) and avoids Roblox's own on-screen buttons.

**Key handling.** Keys are now bound through `ContextActionService`. The I key still lets the camera zoom as it did before. The controller buttons block Roblox's default Backpack from also reacting to LB/RB.

**Review.** I had a separate reviewer check the change. It found five issues and I fixed all of them. The most important: a short PC window was getting the touch layout. Layout is now chosen by input type only.

**Decisions for you:**
- **Controller button choices:** I picked LB/RB, Y and X without knowing which buttons the placement dev is using. They're defined in one table at the top of `Main.client.luau`; please confirm with them before launch. Right now nothing places blocks with a controller, so on Xbox players can switch blocks and toggle build mode but can't place anything until their part lands.
- **PC text size:** desktop text is still 14px, below the usual 18px minimum for PC. I left it alone to keep PC unchanged; raising it is a one-line change in the `DESKTOP` table in `Hud.luau`.

**Also added:**
- **UI Labs story:** `ServerScriptService/Stories/Hud.story` (plus a storybook) lets you switch between the three layouts in Studio. The touch layout's position follows Studio's viewport size, not the preview frame.
- **Strict mode:** Vide's strict mode is now turned on in Studio, to catch mistakes in the UI code early.

**Please check in Studio's Device Emulator:**
- **Small phone (667×375):** the two-row hotbar fills the gap exactly, so check it doesn't clip.
- **Very small phones:** where the gap is too narrow, the hotbar moves right toward the jump button and overlaps the edge of the thumbstick area. Check that tapping slots there still works.
- **Tablet:** the layout fits.
- **1080p and 4K:** desktop matches the old look.
- **Xbox:** button pictures show correctly, and nothing is too close to the screen edges.
- **Switching input:** switch devices while a playtest is running.
- **Largest text size:** check the fixed-size buttons at Roblox's Largest text size setting, because the text could clip.

**For later:**
- **Inventory screen:** when it's built, it needs a starting selection for the controller and must close with B.
- **Controller on a phone or tablet:** I worked out this case on paper but haven't tested it. The hotbar moves above the side buttons there.