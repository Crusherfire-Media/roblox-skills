I built both components from the Figma frame and mounted them in `GameGui`, wired to HudData. StyLua, selene and the type checker pass on every file I touched. I haven't run any of it in Studio: no Studio connection was available here, so the stories haven't been mounted and the layout hasn't been measured against the design. A few command-line checks were also blocked by permissions, so I worked around them.

**What's in place**
- **`UI/CoinCounter.luau`**: the coin pill, top center. Amounts show with thousands separators (`12,450`), and the pill widens with the number while staying centered.
- **`UI/QuestCard.luau`**: the quest card, top right, with title, description and a progress bar with an `n/goal` count. The card grows downward with its text.
- **`Main.client.luau`**: reads coins and the quest from HudData and updates both whenever `Changed` fires. I also moved its requires to the string-require style the new files use.
- **Supporting files**:
  - `UI/Theme.luau` holds the colors, fonts and sizes from the design.
  - `UI/HudAssets.luau` holds the icon image ids, currently placeholders.
  - There are UI Labs stories for both components in `ServerScriptService/Stories`. The quest story can switch between the design's text, very long text, and a quest with no description.
- **Sizes:** the designer's 4K canvas is twice the 1080p size the project builds for, so every size is half the Figma value. On a 4K screen, the existing `Screen.uiScale` doubles them again.

**Long text:** titles wrap to at most 2 lines and descriptions to at most 4. Anything longer is cut off with "…", so a long quest can't cover the game. A quest with an empty description hides that line.

**Images:** the coin (with its glow) and the quest scroll are images on one shared sheet. `HudAssets.luau` describes the layout to export: 256×128 at 2x, coin in the left cell, scroll in the right. The sheet id is `rbxassetid://0` for now, so both icons draw empty until you upload it.

**Where it differs from the design**
- **Background blur on the coin pill:** Roblox can't blur what's behind one frame, so I used a darker fill (40% see-through instead of 50%).
- **Shadows:** I used the Figma numbers, but Roblox draws blur differently, so they may need tuning by eye.
- **Position:** both pieces are placed from the top of the area below Roblox's top bar, so they sit about one top-bar height lower than in the Figma frame. Also, the quest card's top-right spot is where Roblox's player list opens; you may want to hide the player list or move the card.
- **States the design doesn't cover:** I filled in the empty description and the long text from the existing styles. A completed quest just shows a full bar. These are worth a look from the designer.

**Please check in Studio**
1. Open the `QuestCard` story and pick the long text. The cut-off at 2 and 4 lines relies on Roblox's size limit and auto-size working together. I'm not sure that combination behaves as expected, especially on a 4K screen where the UI is scaled up.
2. Compare both stories with the Figma frame: icon alignment, how thick the text outline on the coin amount looks, and the card's gradient, border and shadows.
3. Playtest with the device emulator on a small phone. At 360 wide, the card takes up most of a phone's width, and the design has no phone layout.

Vide strict mode is never turned on. Adding `Vide.strict = RunService:IsStudio()` right after Vide is first required would catch more mistakes during development. Nothing is committed.