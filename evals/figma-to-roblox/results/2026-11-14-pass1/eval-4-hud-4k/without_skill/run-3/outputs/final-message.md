I built `UI/CoinCounter.luau` and `UI/QuestCard.luau` with Vide and mounted both in `GameGui` in `Main.client.luau`. All four project checks pass: the sourcemap rebuild (which updated the tracked `sourcemap.json`), luau-lsp with 0 errors and 0 warnings, selene and stylua. I haven't run it in Studio, so nothing has been checked by eye yet.

**4K canvas:** every Figma value is halved. Our UI is laid out for a 1080-pixel-tall screen, and `Screen.uiScale()` doubles it on a 4K screen, so it ends up the size the designer drew. For example, the 720 px card is 360 here, 48 px text is 24, and a 4 px stroke is 2.

**Live data:** `Main` reads coins and the quest from `HudData` and updates both whenever `Changed` fires. The components just receive those values.

**Coin counter:** a pill at the top centre whose width grows with the number. Amounts get thousands separators (12450 shows as "12,450"), with a black outline on the text and a glow behind the coin.

**Quest card:** fixed to the top right. It keeps its width and grows downward as titles and descriptions wrap. The progress bar takes whatever width the "6/10" count leaves, so bigger numbers fit.

**Things to know:**
- **Text limits (my choice, not in the design):** titles stop at 2 lines and descriptions at 5, then end in "…". Without a limit, a very long quest would run down the screen. The limits are constants at the top of `QuestCard.luau`.
- **Placeholder images:** these are all `rbxassetid://0`, so they show nothing until real art is uploaded. That's the coin icon, the coin's glow, the scroll icon and the card's shadow. The shadow image is stretched from its centre (9-slice), and the coordinates of that centre need to match whatever image gets uploaded.
- **Background blur dropped:** Figma's blur behind the coin pill has no Roblox equivalent, so the pill is just 50% black.
- **Shadows:** Figma has two shadows on the card. I used one image for the larger shadow and left out the faint 2 px one.
- **Top bar spacing:** `GameGui` still keeps clear of Roblox's top bar, so the coin pill and card sit about 58 px lower than in the Figma frame. If you want them exactly where the design puts them, set `ScreenInsets` to `None`. The catch is the coin pill could then end up under the top bar on some devices.
- **One change you didn't ask for:** I set `ResetOnSpawn = false` on `GameGui`. Without it the whole HUD disappears the first time the player respawns, because the script that builds it doesn't run again.