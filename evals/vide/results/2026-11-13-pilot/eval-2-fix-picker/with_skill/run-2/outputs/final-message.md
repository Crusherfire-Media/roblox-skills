I cleared the four type-check errors the stop hook flagged. Nothing in the picker code caused them: `sourcemap.json` was out of date and didn't list `BlockTypes`, `BlockPicker` or `BlockPlacer`. That file is generated and isn't tracked in git, so I rebuilt it with `rojo sourcemap`. With the new sourcemap, `BlockPicker.luau` and `Main.client.luau` type-check with no errors.

The check still reports errors inside the Vide package itself (`context.luau`, `show.luau`, `create.luau`). They come from type syntax in Vide 0.4.1 that this version of luau-lsp doesn't understand, which is outside this task, so I left them alone.

The picker fixes from my last reply haven't changed, and they still haven't been playtested in Studio.