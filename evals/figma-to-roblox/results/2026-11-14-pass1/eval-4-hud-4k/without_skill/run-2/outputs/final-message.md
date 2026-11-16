I've built the coin counter and the quest card and mounted both in `GameGui`. luau-lsp, selene and stylua all pass, but I haven't run any of it in Studio, so nothing has been checked visually yet. The checks ran through PowerShell; an earlier Bash command was blocked because it needed approval and this session has nobody to approve it.

**Scale.** All Figma measurements are halved. The UI is laid out for a 1080p screen, and `Screen.luau` scales it up 2× on 4K, so the cards come out at the designer's exact size there. For example, the 720px card is written as 360 and the 48px title as 24.

**`UI/CoinCounter.luau`**
- The pill sits at the top center and widens to fit the number. Coins show with commas (12,450).
- The number has a 2px black outline.
- The coin icon is a placeholder image tinted to the design's gold, so the real asset should be a white coin shape. A second placeholder image behind it stands in for the glow.

**`UI/QuestCard.luau`**
- The card sits at the top right with a fixed width and grows downward to fit its text.
- It has the design's gradient background, rounded corners, outline, and a placeholder shadow image.
- **Long text:** titles and descriptions wrap. Titles stop at 2 lines and descriptions at 4, ending in "…", so a long quest can't push the card off the screen, especially on phones where the UI isn't scaled down. That cap is my choice, not the designer's; to let the card grow without a limit, delete the two `UISizeConstraint` max sizes.
- The progress bar fills by `Progress / Goal`. It's kept between empty and full, and shows as full when the goal is 0. The bar gives up whatever width the count text needs, so "120/1000" fits as well as "6/10".

**Data.** Each component reads `HudData` itself and refreshes when `HudData.Changed` fires. The connection is closed when the UI is unmounted.

**`Main.client.luau`** mounts both cards, and I also set `ResetOnSpawn = false` on `GameGui`. That fixes a bug that was already there: the gui is created once by this script, so with the default setting Roblox would have destroyed it the first time the player respawned, HUD included.

**Differences from the design:**
- **Background blur:** Roblox UI has no background blur, so the pill's blur is left out.
- **Drop shadows:** the card's two Figma shadows are combined into one shadow image.
- **Line height:** Roblox sets line spacing as a multiple of the font size, so the line heights are close to the design but may not match it exactly.

**Placeholders still to replace:** all four images use `rbxassetid://0`, set at the top of each file:
- `COIN_ICON_IMAGE` and `COIN_GLOW_IMAGE` in `CoinCounter.luau`
- `QUEST_ICON_IMAGE` (the scroll with its seal, in full color) and `SHADOW_IMAGE` in `QuestCard.luau`. Its `SHADOW_SLICE` values are a guess and need adjusting to the real shadow image.

Nothing is committed.