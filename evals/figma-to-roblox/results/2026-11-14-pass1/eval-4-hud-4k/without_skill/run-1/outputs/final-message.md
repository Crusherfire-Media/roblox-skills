I've built the coin counter and quest card with Vide and mounted both in `GameGui`. Selene reports 0 errors and 0 warnings, and the stylua format check passes. I haven't run it in Studio, so nothing has been checked visually or at runtime yet.

**Scale:** our UI is laid out for a 1080-pixel-tall screen, and `Screen.uiScale()` doubles it on a 4K screen. So I divided every value in the designer's 4K frame by 2: the quest card is 360 wide with 16px padding, the title is 24pt, and so on. On a 4K screen it comes out at the designer's exact sizes.

**`UI/CoinCounter.luau`:** a semi-transparent black pill at the top centre. It shows the coin count with thousands separators (12,450) in Builder Sans ExtraBold with a black outline. The pill widens to fit bigger numbers.

**`UI/QuestCard.luau`:** a fixed-width card in the top-right corner with the designer's gradient, border, corners, icon, title, description and green progress bar with a count like "6/10".
- **Long text:** titles and descriptions wrap and the card grows downward to fit. Titles are capped at 2 lines and descriptions at 4, with "…" after that, so a very long quest can't run down the screen. If you'd rather show the full text however long it is, delete the two `UISizeConstraint`s.
- **Progress bar:** the bar stays between 0 and 100% full, and a quest with a goal of 0 shows as complete.

**Data:** both components read from `HudData` when they're created and update whenever `Changed` fires.

**Placeholder images (`rbxassetid://0`):** the coin icon, the coin's glow, the quest scroll icon, and the card's drop shadow. Roblox can't draw shadows or glows itself, so those need images. The shadow code assumes a 128×128 image whose blur fills a 32px border on each side. If the real image is different, change `SHADOW_SLICE_CENTER` and `SliceScale`.

**Three things I changed or left out that you should know about:**
- **Measured from the very top of the screen:** I set `GameGui.ScreenInsets` to `DeviceSafeInsets`. The designer's positions are measured from the top edge, not from below Roblox's top bar; phone notches are still avoided. The pill's centre spot is clear of the top-bar buttons, and the card starts below them.
- **HUD survives respawns:** I set `GameGui.ResetOnSpawn = false`. The GUI is created once from a script, so without this the whole HUD would disappear the first time the player respawns.
- **Not reproduced:** Roblox has no background blur for UI, so the pill's frosted-glass effect is missing. The card's border is drawn on the outside of the card instead of centred on its edge, which is a 1px difference.

The approval prompt blocked two commands. One was a file listing, which I replaced with file searches. The other was running stylua to reformat, so I made its three line-wrapping changes by hand and re-ran the check, which passes.