The two `luau-lsp` errors are false alarms, so I left the file as it is:

- **`@lute/process` (line 5):** this is a module built into Lute, and `luau-lsp` here is set up for Roblox, so it doesn't know the `@lute` prefix and goes looking for a file instead. `overview.luau` uses the same require.
- **`./LibMP` (line 6):** `LibMP.luau` sits next to the scripts on your machines but isn't committed, so the checker can't find it in the repo. `overview.luau` has the same require.

Both requires are correct when the script runs under Lute with `LibMP.luau` beside it. The script is still untested, since commands were blocked in this session.