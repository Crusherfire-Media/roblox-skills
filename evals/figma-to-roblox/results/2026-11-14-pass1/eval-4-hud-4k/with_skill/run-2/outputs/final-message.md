I've built the coin counter and quest tracker and mounted them in `GameGui`. Type-check, selene and stylua all pass. I couldn't run any of it in Studio, so the stories haven't been mounted, nothing has been measured against the design, and no playtest has been run.

## What I added

- **`UI/CoinCounter.luau`**: the coin pill. It shows the coin count with thousands separators ("12,450") and gets wider as the number grows.
- **`UI/QuestCard.luau`**: the quest card. Title and description wrap onto as many lines as they need. The card keeps the design's width and grows downward, so long text is never cut off. If a quest has no description, that line is hidden. The progress bar animates when progress changes, and handles a goal of 0 or progress beyond the goal.
- **`UI/HudTheme.luau`**: every color, font and size from the Figma file, in one place.
- **`UI/HudAssets.luau`**: the image ids for the coin and the scroll icon. Both use Roblox's built-in placeholder image for now. Export the coin at 96×96 with its glow included, and the scroll at 48×48.
- **`Main.client.luau`**: mounts both components and updates them whenever `HudData.Changed` fires. The connection is cleaned up when the UI is destroyed.
- **UI Labs stories** in `ServerScriptService/Stories/HUD/` for both components. The quest card story has switches for long text and no description, plus progress and goal sliders. The coin story's slider goes up to a billion.

## How I converted the 4K design

All Figma sizes are halved, because the project's UI is authored for a 1080-pixel-tall screen and scaled up on bigger ones. It shows at the designer's original size on a 4K screen.

## Changes from the design

- **Background blur on the coin pill:** Roblox can't blur what's behind a single frame. I used a slightly darker fill instead (60% opaque black rather than 50%).
- **Shadows:** the card's two drop shadows use Figma's numbers as a starting point. Roblox draws blur differently, so they may need adjusting by eye.
- **Screen insets:** I set `GameGui` to measure from the top of the screen (`ScreenInsets = DeviceSafeInsets`), because that's where the design measures from. This puts the coin pill in the empty middle of the Roblox topbar row, and the quest card just below the topbar buttons. Note this also applies to anything else you put in `GameGui` later. If you'd rather keep everything below the topbar, remove that line and everything will sit about 58 pixels lower than in the design.
- **Quest icon alignment:** the icon is centered next to the title, as in the design. When the title wraps to two lines it sits between them, not beside the first line.

## Worth knowing

- **Phones:** there's no separate phone layout. On a small phone a quest with a very long description could make the card tall enough to reach the jump button. A narrower phone version of the card would fix that if you want one.
- **Code style:** the new files and `Main.client.luau` use `--!strict` and string requires, which follow the project's style guide. `Screen.luau`, `HudData.luau` and `BlockPlacer.luau` still use the older style; I left them alone.
- **Strict mode:** the project doesn't turn on Vide's strict mode for Studio. Adding `Vide.strict = RunService:IsStudio()` would catch more mistakes while developing.

## What to check in Studio

1. Open "Game UI → HUD → QuestCard" in UI Labs. Turn on long text, try progress at 0 and above the goal, and turn off the description. Then open the CoinCounter story and drag the slider to a large number.
2. Compare both against the Figma frame at half size: the card should be 360 wide, 24 from the right edge and 80 from the top. The pill should be 44 tall and 20 from the top.
3. Run a playtest at 1080p and at 4K, and confirm the pill and card stay clear of the Roblox topbar buttons.