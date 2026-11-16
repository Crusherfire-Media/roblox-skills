I've reworked the ghost previews, and lint, format and type checks all pass. I couldn't run Studio from here, so nothing has been tested with multiple players yet, and the new spec hasn't run.

**How it works now**
- **Client** (`GhostPreview.client.luau`): your own ghost is drawn on your screen every frame, straight from your cursor. It no longer waits a round trip to the server, so it should feel more responsive than before. The client only tells the server when the ghost changes cell, block type or visibility, and never more than 20 times a second. The last change before the cursor stops always gets sent. It also stops sending every frame while placing is off.
- **Server** (`GhostPreview.server.luau`): it no longer has ghost parts. It checks each update, keeps the latest state for each player, and up to 20 times a second sends all the changes to everyone in one message. It sends nothing when nothing changed. Someone who joins gets a snapshot of everyone's current ghost. A client sending more than 60 messages a second is ignored for the rest of that second.
- **Other players' ghosts** are drawn on each client and glide toward their latest cell instead of jumping. Jumps longer than 32 studs snap instead.
- **New shared module** `src/ReplicatedStorage/Shared/GhostProtocol.luau` holds the message format and the input checks used by both sides. `Tests/Specs/GhostProtocol.spec.luau` tests it.
- Placing blocks is unchanged. It still uses `PlaceBlock`, and the ghost uses the same grid snapping as before.

**Traffic estimate** (in `docs/perf/ghost-network.md`, with the working). These are estimates, not measurements, since Roblox doesn't publish its message sizes. For 12 players building, with frame rates between 60 and 240 FPS:

| | Before | After |
|---|---|---|
| Messages into the server | ~1,776/s, ~57 KB/s | ~96/s, ~3.3 KB/s |
| Upload per player at 240 FPS | 7.7 KB/s | ~0.27 KB/s, at most 20 messages/s |
| Upload while the cursor is still | 1.9–7.7 KB/s | 0 |
| Data out of the server | ~26 KB/s | ~26 KB/s, in at most 20 batched messages/s per player |

The big saving is the flood of messages into the server, which is what pushed ping up. Data going out stays about the same, because before it only went out when a ghost changed cell anyway.

**What players will notice** (also listed in the doc):
- Your own ghost reacts on the same frame as your cursor.
- Other players' ghosts glide smoothly but run about 75–125 ms behind a perfect connection. Under load they used to be 300–400 ms behind and jumpy.
- When someone sweeps across more than 20 cells a second, their ghost follows a rounded path instead of stepping through every cell.
- `Workspace.Ghosts` now exists separately on each client, so the server view in Studio shows no ghosts.

To confirm the numbers, run a multi-client Studio test and watch the Network stats in the Developer Console (F9). Nothing is committed.