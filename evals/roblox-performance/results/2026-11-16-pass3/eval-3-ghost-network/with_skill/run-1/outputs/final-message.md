I've reworked the ghost previews, but none of this has been run in Studio yet. The traffic numbers are estimates built from measured per-message byte costs, not measured in your game. luau-lsp, selene and stylua all pass, and a Roblox-specific review found no blockers.

**How it works now**
- **Your own ghost is drawn on your own client**, the same frame your cursor moves. Before, it was the server's part, so it trailed your cursor by your ping (300–400 ms in your test). It's now more responsive than before, not just as responsive.
- **The client only sends when its ghost changes**: at most 20 times a second, plus one refresh a second in case a message was lost. Frame rate no longer matters. Each update is about 23 bytes and goes on an unreliable remote (`SendGhost`), so it can never hold up `PlaceBlock`.
- **The server no longer has ghost parts.** It keeps each player's latest ghost in a table. Every 1/20 s it sends everyone one combined message (`GhostUpdates`) with only the ghosts that changed, and once a second it sends all of them.
- **Each client draws other players' ghosts itself** and glides them to each new cell (about 0.1 s), instead of snapping.
- Placing blocks is untouched: `BlockPlacer.luau` and `BlockPlacement.server.luau` didn't change, and the old `MoveGhost` remote is gone.

**Estimated traffic at 12 players** (the full working is in `docs/perf/ghost-network.md`)

| | Before | After |
|---|---|---|
| Ghost messages the server receives | 720–2,880/s, even when nobody is building | 12/s idle, 240/s at most |
| Upload per client | 1.7–7 KB/s, all the time | 23 B/s idle, 0.46 KB/s at most |
| Download per client, 12 people building | 6–18 KB/s | at most 3.9 KB/s |

The biggest saving is on the upload side. Before, every client sent a message every frame even when not building, all on the same queue as `PlaceBlock`. With only a few builders, server-to-client bytes are about the same as before. That traffic is now capped, combined into one message, and on a queue that can't hold up anything else. That's my best explanation for the high ping and the jumping ghosts, but it hasn't been measured. The doc has the Studio steps to confirm it.

**What players will notice** (also listed in the doc):
- Other players' ghosts glide instead of snapping, and run a bit behind their cursor: both players' ping, plus up to 50 ms of batching, plus the glide.
- A fast sweep skips cells instead of visiting each one.
- A ghost moving more than 24 studs jumps instead of gliding.
- If a message is lost, a ghost can sit in the wrong cell for up to about 2 seconds.
- Players who join see other players' idle ghosts within a second.

**Still open:**
- **The server doesn't check where a ghost is.** A modified client can put its ghost anywhere, for example right in front of someone's camera. The old code had the same gap and also accepted NaN; the new one only accepts whole-number cells. I could hide ghosts beyond the 64-stud placement reach, but that changes what other players see, so I left it for you to decide.
- **There's no per-player limit on `SendGhost`.** Spamming it only costs the server some CPU. It adds no traffic for other players, because outgoing updates are capped at 20 a second.
- **No tests yet.** I'd add specs for the new `GhostCodec` module: encoding and decoding round-trip, and rejecting a wrong type, wrong length, or unknown block type. Tell me if you want those; they can only run in Studio.

Nothing is committed. The changes are in the two `GhostPreview` scripts, plus the new `src/ReplicatedStorage/Shared/GhostCodec.luau` and `docs/perf/ghost-network.md`.