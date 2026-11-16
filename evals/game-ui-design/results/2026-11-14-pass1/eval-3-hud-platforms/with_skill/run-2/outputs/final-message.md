The HUD now has three layouts: PC, touch and controller. It switches between them live when the player changes input, for example picking up a controller on PC, using a new module, `UI/Screen.luau`. The type checker, selene and StyLua all pass. Nothing has run in Studio, so none of it has been seen on screen or tested in a playtest yet. I haven't committed anything.

**PC.** It looks and behaves the same, apart from four changes:
- The build mode line in the bottom left is now a clickable button. It still shows `[B] Build: On/Off`.
- Text went from 14 to 18 px (the Xbox accessibility guidelines suggest 18 for PC) and the buttons are wider to fit it.
- The selected block's name now shows above the hotbar all the time. Hovering a slot still previews that slot's name in the same place.
- On 1440p and 4K screens the whole HUD grows (1.33× and 2×). Before, it got smaller relative to the screen as resolution went up.

**Controller and TV.**
- **Layout:** same places as PC, kept 5% in from the edges because some TVs crop. Text is sized to meet the Xbox guideline of 26 px on a 1080p TV.
- **Blocks:** LB/RB cycle through them, wrapping at the ends, with the button icons shown at each end of the hotbar.
- **Buttons:** X turns build mode on and off, Y opens the inventory, and both show their icons.
- **Narrow screens:** on a tablet or phone with a controller, the two corner buttons move up above the hotbar so they don't overlap it. A narrow PC window does the same.

**Touch.** The bottom corners are left clear for Roblox's thumbstick and jump button.
- **Block button:** next to the jump button, sized and placed the way Roblox's own sample action button is. It shows the current block's color and name.
- **Block picker:** tapping the block button opens a picker of all ten blocks with their names, in a 5×2 grid. Tapping a block picks it. Tapping outside the picker, or the X, closes it, and those taps don't place a block.
- **Build mode and inventory:** these sit top right under the coins, at 104×56.

**Decisions for you:**
- **Two taps to switch blocks on touch.** Ten slots at a size thumbs can hit don't fit between the thumbstick and jump button on a small phone, so touch players open the picker and then tap a block. It's worth a playtest with a few kids to see whether they find the block button and don't mind the extra tap.
- **Controller buttons:** LB/RB, X and Y are set in `Main.client.luau`. Please check with the dev doing controller placement that none of these clash with their bindings.
- **Backpack turned off:** I turned off Roblox's default Backpack, because its controller bindings would also grab LB/RB. The repo has no Tools, so nothing should change for players.
- **Picking the touch layout:** it follows Roblox's own pick of the player's main input. A tablet with a keyboard attached therefore gets the PC layout, which still works with taps.

**Not verified:**
- **Studio:** I couldn't reach Studio, so I haven't run the UI Labs story check, measured the layout, or played it in the Device Emulator.
- **Jump button clearance:** the touch layout positions are calculated from Roblox's default jump button layout, not measured. On phones with a notch, the jump button and the HUD may measure from different edges.
- **Picker over the thumbstick area:** whether the picker or the thumbstick wins a press there hasn't been tested.
- **Swapping controllers:** if a player swaps an Xbox controller for a PlayStation one mid-session, the button icons don't update until the input type changes.

**To check in Studio:** open the new **Game UI › Hud** story in UI Labs. It has controls for the layout, the jump button size and the screen width, and narrowing the width shows the corner buttons moving up. Then playtest in the Device Emulator on a small phone (667×375), a tablet, 1080p, 4K and Xbox, and switch devices during the playtest to watch the HUD follow.

A Roblox reviewer agent checked the change before I reported back. I fixed what it found: the corner buttons overlapping the hotbar on narrow screens, taps in the picker's gaps closing it, and short PC windows switching to the touch layout.

Two smaller things you may want: `Vide.strict = RunService:IsStudio()` isn't set anywhere, and it would catch Vide mistakes in Studio. I also kept `local` rather than `const` and the style guide's other small rules to match your existing files.

**Files:**
- `UI/Hud.luau` (rewritten)
- `UI/Screen.luau` (new)
- `Main.client.luau`
- `ServerScriptService/Stories/Hud.story.luau` and `GameUI.storybook.luau` (new)