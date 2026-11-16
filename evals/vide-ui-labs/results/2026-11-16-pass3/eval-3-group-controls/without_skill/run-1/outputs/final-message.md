I've regrouped the BlockTile story's 13 controls into 4 groups, each with a fixed order, so the panel should look the same every time it reloads. I haven't seen it in UI Labs, and I couldn't run a linter because the permission prompt was blocked in this session. All changes are in `src/ServerScriptService/Stories/BlockTile.story.luau`; BlockTile itself is untouched.

| # | Group | Controls, in order |
|---|---|---|
| 1 | **Content** | Block, NameOverride, Count, ShowName, ShowCount |
| 2 | **State** | Selected, Locked |
| 3 | **Appearance** | TileSize, CornerRadius, HighlightColor, HighlightThickness |
| 4 | **Story** | Backdrop, Centered |

**How it works:**
- Each control is wrapped in `UILabs.Ordered(..., n)`. Every control keeps its old default, range and option list.
- Groups use `UILabs.ControlGroup`. In this version of UI Labs (2.4.2), the Luau `ControlGroup` doesn't accept an order, even though its type definitions say it does. So a small `group(order, controls)` helper in the story sets the group's `Order` field directly, which is what the panel reads.
- Grouped controls arrive nested (for example `props.controls.Content.Block`), so I updated `StoryProps` and every place the story reads a control. Each one still feeds the same BlockTile prop or the same backdrop/centering logic as before, and no flat `controls.X` references are left.

Saved control values may reset to their defaults once after this change, because the controls now live under new group paths.