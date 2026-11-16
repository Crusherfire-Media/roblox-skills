I put the 13 controls into four groups, and both the groups and the controls inside them now have a fixed order:

1. **Content**: Block, NameOverride, ShowName, Count, ShowCount
2. **State**: Selected, Locked
3. **Appearance**: TileSize, CornerRadius, HighlightColor, HighlightThickness
4. **Story**: Backdrop, Centered

I changed only `src/ServerScriptService/Stories/BlockTile.story.luau`. Every control keeps the same default, range and options, and still drives the same BlockTile prop or backdrop/holder setting. The only code change is how the story reads them: now through their group (for example `content.Block()` instead of `controls.Block()`). I updated `StoryProps` to the nested shape.

The fixed order comes from `UILabs.Ordered`, applied to each control and each group. One thing behaved differently than you might expect: in the Lua version of UI Labs 2.4.2, `ControlGroup` ignores an order argument (only the TypeScript typings accept one). So each group is wrapped in `Ordered` instead, which works on a group too.

The type check, selene and stylua all pass with no errors or warnings. I couldn't open Studio from here, so I haven't seen the panel itself. Please reload the story once to confirm the order holds.

Placing Centered under **Story** was my call, since it only moves the tile within the preview. Move it if you'd rather have it elsewhere.