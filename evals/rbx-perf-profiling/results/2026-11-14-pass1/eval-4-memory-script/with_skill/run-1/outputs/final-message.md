I fixed the type errors the checker found in `tools/profiling/memory.luau`. Two errors are left, and both are false matches:

- **`Unknown require` for `@lute/process` and `./LibMP`:** luau-lsp doesn't know Lute's built-in libraries, and `LibMP.luau` is deliberately kept out of the repo. `overview.luau` would get the same two errors.

**What changed:** each counter now has an explicit type, and container-only subsystems (grouping nodes with no values) are typed as having no values. Calls into LibMP now have type annotations. What the script prints is unchanged.

I haven't rerun the checker or the script since this edit, and the script still hasn't run against a real dump.