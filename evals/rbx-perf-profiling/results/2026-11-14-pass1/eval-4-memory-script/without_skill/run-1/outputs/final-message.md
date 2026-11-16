I've written `tools/profiling/memory.luau`, but I haven't run it. `LibMP.luau` isn't in the repo, there was no `.gprx` dump to test with, and my one shell command was blocked by the permission prompt. I built it from LibMP's official API reference and the style of `overview.luau`, so please try it on a real dump before relying on it.

Run it with `lute memory.luau <dump.gprx> [topN]`, with topN defaulting to 10. It prints two things:

1. **Subsystems:** one row per child of `memory` (`memory/Luau`, `memory/physics`, …) showing first, last, peak, growth and the peak frame, sorted by growth with the largest first.
2. **Top N growing counters:** the counters under `memory` that grew the most, each with its full path (e.g. `memory/Luau/heap`) plus its first, last and peak values and peak frame.

**Frame names** use the same `id/abs t=Ns` format as `overview.luau`:
- `id` is LibMP's `FrameId`, for use in our scripts.
- `abs` is `FrameAbsoluteId`.
- `t` is seconds into the dump.

LibMP's docs don't say which of the two IDs the MicroProfiler UI displays; they just recommend reporting both. Seconds into the dump is the fallback for finding the frame in the UI.

Choices I made that you may want to change:
- **Only the lowest-level counters count toward the top N.** A parent may be the sum of its children, so including parents would list the same growth twice. The parents are already in the subsystem table.
- **Values are shown in MB, assuming the counters are in bytes.** That matches the LibMP Luau heap example, but the docs don't promise it for every counter under `memory`.
- **First and last use the first and last sample each counter actually has**, sorted by frame. A counter that starts late in the dump is measured from its first sample.
- **The script looks for `/memory` at the top level first**, and only falls back to any counter named `memory`.

Nothing is committed.

Sources:
- [Roblox/libmp on GitHub](https://github.com/Roblox/libmp) (README, `docs/api-reference.md`, `docs/SKILL.md`)
- [[Studio Beta] Introducing LibMP: the MicroProfiler API](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)