I've reworked the ghost previews, but nothing has been tested in Studio yet: I can't reach Studio from here. Formatting, lint and type checks pass, a Roblox code review found no blockers, and every traffic number in the doc is an estimate.

**What changed**
- **Each client draws all the ghosts itself.** The server no longer creates or moves any ghost parts. Your own ghost is drawn from your own cursor every frame, without going through the server.
- **Clients send their cursor cell only when it changes.** That's at most 20 times a second whatever their frame rate, plus a repeat once a second when nothing has changed. The repeat fixes lost messages and catches up players who join later.
- **The update is a small 9-byte message** (new file `src/ReplicatedStorage/Shared/GhostPacket.luau`). It goes over an unreliable remote (`GhostUpdate`), so ghost traffic can no longer delay block placement or other reliable traffic. Updates that arrive out of order are thrown away.
- **The server just checks and forwards.** It checks each message, limits each player to 25 a second, and passes it on to the other players. Other players' ghosts slide smoothly toward each new cell instead of jumping.
- **Placing blocks is unchanged.** `BlockPlacer` and `BlockPlacement.server` weren't touched. The ghosts still can't be hit by the placement raycast, and the review confirmed the ghost snaps to the same grid cell a block is placed in.

**Estimated traffic** (12 players: 4 building at 240 FPS, 8 idle at 60 FPS). The working is in `docs/perf/ghost-network.md`.

| | Before | After |
|---|---|---|
| Sent from clients to the server | ~42 KB/s, 1,440 messages/s | ~1.9 KB/s, 88 messages/s |
| Received by each client | 6–18 KB/s* | ~2.4 KB/s |

\*The range is there because I don't know if Roblox resends a property when it's set to the value it already has. The old server did that on every message.

The biggest savings are from clients to the server and from moving ghosts off the reliable channel. Downstream, a cursor moving slowly costs about the same as before, since both versions send one message per cell change. The saving comes from fast sweeps, idle players, and not echoing your own ghost back to you. The doc also estimates 24 and 50 players (about 10 KB/s per client at 50).

**What players will notice**
- Your own ghost has no lag. In the test it trailed your cursor by the 300–400 ms ping.
- Other players' ghosts slide between cells (about 0.1 s) instead of jumping, and can cut corners on fast sweeps. Moves of more than 8 cells still jump.
- Someone who joins sees existing ghosts within about a second instead of straight away.
- Rarely, another player's ghost can sit one cell off for up to a second if a message is lost.
- `Workspace.Ghosts` now only exists on each client; the server has no ghost parts.

**For you to check**
- **Measure it.** Run the same multi-player workload on the old and new versions and compare the network numbers (steps are in the doc). Data Ping should come back down to about Network Ping.
- **Look at the sliding.** Check that other players' ghosts look smooth to you. If traffic ever needs cutting further, lowering the send rate in `GhostPreview.client.luau` from 20 to 10 halves the cost.
- **Decide on tests.** I didn't add any. I'd suggest four for `GhostPacket`: positions survive encoding and decoding (including negative cells), out-of-range cells are sent as hidden, bad messages are rejected, and message order still works after the counter wraps from 65535 to 0. Say if you want them; they can only run in Studio.

Nothing is committed.