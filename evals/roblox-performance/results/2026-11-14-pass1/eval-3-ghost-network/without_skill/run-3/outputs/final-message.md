I've reworked the ghost previews so ghost traffic no longer grows with frame rate or with how many players are idle. All the project checks pass, but none of this has been run in Studio or tried with real players yet. The traffic figures in the doc are estimates on paper, not measurements.

**How it works now**
- **Shared format (`src/ReplicatedStorage/Shared/GhostCodec.luau`, new):** each ghost is packed into a few bytes (block type, then the cell as three small integers). There is one send rate, 20 per second, used by both client and server.
- **Client (`GhostPreview.client.luau`):**
  - **Your own ghost** is a part that exists only on your machine and moves every frame, so it no longer waits a round trip to the server. It should feel more responsive than before.
  - **Sending:** your client only tells the server when your cell, block type or visibility changes, and at most 20 times a second. Before, every client sent a message every frame, even players who weren't building.
  - **Other players' ghosts** are also local parts. They glide toward the newest cell each frame, and jump straight there if it's more than 32 studs away.
- **Server (`GhostPreview.server.luau`):** it no longer owns or moves any ghost parts. It stores each player's latest state and, 20 times a second, sends one batch containing only the ghosts that changed (nothing if none did). Each player gets a small slot number in a `GhostSlot` attribute so the batches can stay small. A player's first message gets them a snapshot of every visible ghost, so people who join late see existing ghosts. When a player leaves, their ghost is hidden.
- **Placing blocks:** unchanged. The ghost parts still don't block the click raycast.

**Estimates (`docs/perf/ghost-network.md`)**
The doc lists each assumption (bytes per message, a 12-player server with 3 players at 240 FPS, a builder changing cell about 15 times a second). Main figures:

| | Before | After |
|---|---|---|
| Upload from one 240 FPS client | 7.2 KB/s, 240 messages/s | at most 0.4 KB/s, at most 20 messages/s |
| Total arriving at the server | 37.8 KB/s, 1,260 messages/s | 1.2–4.8 KB/s, 60–240 messages/s |
| Download per client, all 12 building | about 14.4 KB/s, up to 720 updates/s | about 2.2 KB/s, 20 messages/s |

Most of the saving is on the way into the server, and that is probably what caused the ping spikes. Downloads in the typical case are about the same size, but now have a fixed limit of 20 messages a second.

**What players will notice** (also listed in the doc):
- Your own ghost moves with your cursor instantly.
- Other players' ghosts glide between cells and may briefly sit between two cells. They also add up to about 50–100 ms of delay on top of ping, partly offset by ping itself being much lower.
- When a builder flicks the mouse fast, other players see the ghost slide straight to where it lands instead of visiting each cell.
- `Workspace.Ghosts` and the `MoveGhost` remote are gone. They're replaced by a `Workspace.LocalGhosts` folder on each client and two remotes, `GhostState` and `GhostUpdates`. Nothing else in the project used the old names.

I picked reliable remotes over unreliable ones on purpose. Unreliable ones could drop a builder's last update and leave their ghost stuck in the wrong cell for everyone else.

Checks: the type checker found 0 errors, and the linter and formatter reported nothing. Running the sourcemap step updated `sourcemap.json`, since there's a new module. Nothing is committed. To confirm the numbers, run a 12-player test and watch Studio's network stats (Shift+F3).