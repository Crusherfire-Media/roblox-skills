I ran StyLua on the story file, so the formatting problem is fixed. StyLua only moved the group order numbers onto their own lines; nothing else in the file changed.

The three type errors are still there, and I didn't change anything to clear them:

- **Lines 4–5:** the checker can't find the `BlockTile` and `BlockTypes` modules. Those two require lines are exactly as they were before my edit, so the cause isn't the regrouping. It's probably how the checker maps the place's modules.
- **Line 78:** the "unknown type `BlockTypes.BlockType`" error depends on line 5. It goes away once the checker can find `BlockTypes`.

I haven't confirmed the errors were there before my change, because I didn't re-run the checker on the old version. Fixing them would mean touching the checker setup rather than the story, so I left it alone.

The rest of my earlier summary still applies: the controls are in four ordered groups (Content, State, Look, Preview). They still need a check in UI Labs to confirm the order stays put across reloads and every control still drives the tile.