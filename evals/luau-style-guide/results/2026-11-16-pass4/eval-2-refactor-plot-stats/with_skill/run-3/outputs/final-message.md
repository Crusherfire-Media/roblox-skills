I've fixed the four type errors the stop hook reported. I still can't run luau-lsp or StyLua in this session, so these fixes haven't been checked. The stop hook will re-run the analyzer.

- **Line 48, comparing `Vector3` with `nil`:** `isCountedBlock` now copies the position into a local typed `Vector3?` before checking it for `nil`. It still skips blocks without a `Position`, which callers that aren't type-checked can pass in.
- **Line 88, `rest` might be `nil`:** the check now covers `rest` as well. Nothing changes at runtime, because `rest` is only `nil` when the number itself didn't match, and that case already errored.
- **Line 120, indexing `counts` with a block type:** I removed the `BlockType` list of literal type names. `BLOCK_COST`, `BLOCK_TYPES`, the counts map and `Summary.Counts` now use plain `string` keys, and the casts are gone. As a result, `BlockType` is no longer exported, and `Block` and `Summary` are the only exported types.

None of these fixes change what `summarize`, `getTallest`, `format` or `compare` return.