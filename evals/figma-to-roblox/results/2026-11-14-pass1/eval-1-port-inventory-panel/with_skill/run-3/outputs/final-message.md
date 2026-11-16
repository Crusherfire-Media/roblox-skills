All three project checks now pass on `src`: luau-lsp, selene, and `stylua --check`. Studio is still untested, so the UI Labs story check and on-screen layout measurements haven't been done.

- **The "Unknown require" errors** came from an out-of-date `sourcemap.json`. It had no entries for `BlockTypes`, `BlockPlacer`, or the `UI` folder, which is why even `Main.client.luau`'s existing `BlockPlacer` require failed. I regenerated it with the `rojo sourcemap` command from the README, and those errors went away.
- **`InventoryPanel.luau:314`** was a real type error. Vide's `derive` was reading the Equip button's state names as plain strings, so I convert them back where it's read. The button works the same.
- **One more error appeared once the requires resolved:** in `InventoryPanel.story.luau`, the panel and the open button weren't the same type for `show`, which needs both to match. I marked both as `Instance`.

Since commands can run now, I also confirmed one assumption from my earlier summary: Vide's `create` types don't include `UIStroke`, `UIPadding` or `UIScale`. Going through an untyped `create` for those three is still needed.

`UIShadow`'s exact property names are still unconfirmed, since the type check can't see inside the untyped code that builds it. Check the Output window for a "UIShadow could not be built" warning the first time you play.