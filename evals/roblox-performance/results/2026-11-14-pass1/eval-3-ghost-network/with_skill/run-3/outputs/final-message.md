I've reworked the ghost previews and written `docs/perf/ghost-network.md`. All traffic figures are estimates, built from measured per-message byte costs and assumed usage. Nothing has been run in Studio or a multiplayer test yet. Type check, StyLua and selene all pass.

**What changed**
- **No server ghost parts.** Each client draws every ghost itself, in a client-only `Workspace.GhostPreviews` folder. The ghosts can't be hit by raycasts, so placement clicks pass through them as before.
- **Your own ghost is drawn locally every frame** with no network round trip. Before, it came back from the server, so it trailed your cursor by your full ping (300–400 ms in your test).
- **The client sends only when its cell or block type changes,** at most 25 times a second at any frame rate (20 in practice at 60 FPS). It goes on an `UnreliableRemoteEvent` as a 9-byte buffer, and is resent once a second in case a message was lost.
- **The server sends one batch to everyone 20 times a second,** holding only the ghosts that changed, plus a full update once a second. A client spamming the remote can't raise what the server sends: each player gets at most one entry per batch.
- **Other players' ghosts are smoothed.** Each client draws them slightly in the past and glides between updates, with a delay that adjusts to that client's ping.
- **The message format lives in one new module,** `src/ReplicatedStorage/Shared/GhostCodec.luau`. `BlockPlacement.server.luau` and `BlockPlacer.luau` are untouched.

**Estimated traffic, 12 players** (the doc shows the arithmetic)

| | Before, 4 building | After, 4 building | Before, all 12 | After, all 12 |
|---|---|---|---|---|
| Server receives | 33 KB/s, 1,440 calls/s | 2.3 KB/s, ≤108 calls/s | 84 KB/s, 2,880 calls/s | 6.3 KB/s, ≤300 calls/s |
| Each client receives | 2–6 KB/s | 1.1 KB/s | 18 KB/s | 2.6 KB/s |
| Server sends in total | 24–72 KB/s | 15 KB/s | 216 KB/s | 32 KB/s |

There's no ghost traffic left on the reliable channel that block placement and everything else the server sends share. That shared queue backing up is the likely cause of the ping spikes and the jumping ghosts.

**What players will notice**
- Your own ghost is instant.
- Other players' ghosts glide instead of snapping, and during a fast sweep they can briefly sit between cells. They always stop on the right cell.
- On a quiet server, other players' ghosts trail about 100–190 ms more than before. On a busy server like your test, they should look better overall.
- Players who just joined may see a ghost that isn't moving appear up to 1 s late.
- A rare lost packet can leave someone's ghost on the wrong cell for up to about 1 s.
- `Workspace.Ghosts` no longer exists. Nothing else in the repo used it.

**Review and checks**
- A Roblox review agent found three bugs, all now fixed:
  - A ghost could stay on screen after its player left.
  - The smoothing delay ignored ping, so ghosts would have snapped above about 100 ms.
  - At 60 FPS the send rate was out of step with the server's batches, which made ghosts stop and start.
- The first type check failed with "Unknown require". The cause was an out-of-date `sourcemap.json`, which didn't list the files in `ReplicatedStorage.Shared`. I regenerated it with `rojo sourcemap`; that file isn't tracked in git.

**Not changed**
- The server doesn't check that a ghost cell is within the player's reach. The old version didn't either, so the worst case is someone showing a ghost in a far-off cell.
- The new files don't use `--!strict`, to match the rest of the repo.

**To confirm the numbers:** run a 12-player test on the old and new code with 4 people sweeping their cursors. Compare `Stats.DataReceiveKbps` and `DataSendKbps`, and check whether data ping stays close to network ping. The steps are at the end of the doc. Nothing is committed.