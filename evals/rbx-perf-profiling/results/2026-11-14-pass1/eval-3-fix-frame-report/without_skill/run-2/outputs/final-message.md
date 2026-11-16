I've rewritten `src/ReplicatedStorage/Shared/Dev/FrameReport.luau`. FpsOverlay is untouched. **I haven't tested any of this.** My two attempts to run commands were blocked by the permission system, so I couldn't run a linter or open Studio. I checked each change against LibMP's official docs, but please press the button once in a playtest before relying on the numbers.

## What caused each problem

- **Overlay errors every frame:** the report borrowed the overlay's session with `FpsOverlay.getSession()` and then closed it with `session:Dispose()`. The overlay kept using the closed session.
- **MicroProfiler frozen until rejoin:** the report paused capture with `EnableCapture(false)` and never turned it back on.
- **Overlay "last second" covering about four seconds:** the report set the frame limit to 256 and never set it back. The overlay averages every frame held, so 256 frames is about 4 s at 60 FPS. Changing the limit also wipes counter history.
- **Physics longer than the frame, and too little in the frame before:** two causes.
  - Each scope's whole time went to the frame where it ended. A scope that started in one frame and ended in the next was counted entirely in the second.
  - Nested Physics scopes were all added, so time inside them was counted twice.
- **Nonsense GPU column:** it used the CPU conversion factor instead of the GPU one. Also, the frame's own GPU start and end ticks are unreliable: the end can come before the start (negative values), or one frame can cover several.

## What I changed

- **Own snapshot:** the report copies the MicroProfiler data into its own slot (slot 4), opens its own session on that copy, then closes it and clears the slot. It no longer pauses capture, changes the frame limit or uses the overlay's session.
- **Physics and top scopes:** each scope's time is now split across every frame it overlaps. Physics counts only the outermost Physics scope. For the top-5 list, a timer nested inside itself counts once. Scope totals still include their child scopes, as before.
- **GPU:** the time inside the outermost GPU-thread scopes for each frame, converted with the GPU factor. LibMP's docs say this is the reliable way to measure GPU time.
- **Other fixes:**
  - Frames still in progress are left out, matching what the overlay does.
  - The heap counter array leaked memory because it was never closed; the report now reads the last sample directly.
  - Scope names were read in a way LibMP doesn't support; that's fixed.
  - The Physics group lookup now runs once instead of on every entry.
  - Missing Main thread, Physics group or heap counter are now handled.
  - Cleanup still runs if something fails partway through.

## Behaviour that changed

- **Fewer frames while the overlay runs:** the report can only cover frames the MicroProfiler holds, which is 60 while the overlay is running. So you'll get about 59 frames, not 120. Raising the limit wouldn't help: it doesn't bring back old frames, and it would break the overlay's one-second window again.
- **GPU can show 0:** GpuMs is 0 on platforms with no GPU thread.
- **Slot 4:** if anything else uses MicroProfiler slot 4, change `SNAPSHOT_SLOT`.

Sources:
- [LibMP repository](https://github.com/Roblox/libmp)
- [LibMP API reference](https://github.com/Roblox/libmp/blob/main/docs/api-reference.md)
- [LibMP SKILL.md](https://github.com/Roblox/libmp/blob/main/docs/SKILL.md)
- [LibMP DevForum announcement](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)