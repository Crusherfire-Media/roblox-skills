I added type annotations to `tools/profiling/memory.luau` to fix the type errors the stop hook reported. StyLua reformatted the file without errors. I couldn't re-run `luau-lsp analyze` because the command was blocked for needing approval, so the hook's next check is the first test of the fix.

**What changed:**
- I added a `Series` type for a counter's values per frame and a `Row` type for each output line, and typed the helper functions with them. This should clear the errors on lines 93, 120, 128, 136, 146 and 152.
- `minId` and `maxId` are now set on two separate typed lines, which should clear the "Expression list has 1 value" error on line 19.
- The output is the same as before.

**Two errors are expected and I left them:** the "Unknown require" errors for `@lute/process` and `./LibMP`. luau-lsp doesn't know Lute's `@lute` alias, and `LibMP.luau` isn't committed, so luau-lsp can't find either one. Lute finds both when you run the script from `tools/profiling` with `LibMP.luau` beside it.

The script still hasn't been run against a real dump: there's no `.gprx` file or `LibMP.luau` here.