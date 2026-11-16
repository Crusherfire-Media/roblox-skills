I've reworked the ghost previews. Type checking, selene and stylua all pass, and I added protocol specs in `Tests/Specs/GhostProtocol.spec.luau`. Specs only run in Studio, so those specs haven't run, and nothing has been tested in a live server. The traffic numbers in the doc are estimates, not measurements.

**How it works now**
- **Client** (`GhostPreview.client.luau`):
  - **Your own ghost:** it's drawn locally every frame, so it follows your cursor with no round trip. It was a server part before, so this is more responsive than it was.
  - **Sending:** the client contacts the server only when your cursor moves to a different cell or you switch block type, and at most 20 times a second. A 7-byte message holds the block type and the cell. When nothing changes, nothing is sent; the old code sent a message every frame, even when idle or when placing was turned off.
  - **Other players' ghosts:** each client draws them itself and slides them smoothly toward the latest cell, instead of jumping.
- **Server** (`GhostPreview.server.luau`): there are no server-side ghost parts any more. It keeps each player's latest state and, 20 times a second, sends whatever changed to everyone in one combined message (15 bytes per ghost). Players who join late get everyone's current ghost once, through a new `GetGhosts` request. It also rejects malformed messages.
- **Shared** (`Shared/GhostProtocol.luau`): the message format and the send rates.

Block placement code is untouched.

**Estimates** (in `docs/perf/ghost-network.md`, with the formulas and assumptions). These rest on assumed per-message sizes, because Roblox doesn't publish its wire format:

| 12 players | Before | After |
|---|---|---|
| Messages into the server (playtest-like / worst case) | 1,728 / 2,880 per s | 60 / 240 per s |
| Upload per player | 5.8–9.6 KB/s, always | 0–0.58 KB/s |
| Download per player | 1.5–9 KB/s, up to 360 updates/s | 1.4–4.1 KB/s, at most 20 messages/s |

The worst case grows to about 7.7 KB/s download per player at 24 players. The likely cause of the ping spike was every client sending one message per frame; that is now gone. To confirm the doc's numbers, check the Developer Console's network stats on a real 12-player server.

**What players will notice** (also listed in the doc):
- Your own ghost is snappier.
- Other players' ghosts glide between cells instead of teleporting.
- Other players' ghosts trail the real cursor by roughly 50–150 ms more than raw latency.
- When someone sweeps quickly (more than 20 cells a second), their ghost skips cells, and jumps over 48 studs snap instead of gliding.
- `Workspace.Ghosts` now exists only on each client, so the server and Studio's server view no longer see ghosts. Nothing in the project used them.
- Cells beyond about ±131,000 studs show for the builder but aren't shared with others.

I haven't committed anything.