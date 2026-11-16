I've reworked the ghost previews. I couldn't run them in a game (no Studio here), so the before and after traffic figures in `docs/perf/ghost-network.md` are worked out on paper, not measured. Type checking (luau-lsp), linting (selene) and formatting (stylua) all pass, and a separate review found nothing blocking.

## How it works now
- **Your own ghost** is drawn on your own machine every frame, straight from your cursor. Before, it went to the server and back, so it lagged by your ping (300–400 ms in your test). It should now feel more responsive than before.
- **What your client sends:** only when the cell, block type or show/hide state changes, at most 20 times a second, plus one repeat a second while nothing changes. It no longer depends on frame rate, so a 240 FPS player sends the same as anyone else. The message is an 8-byte packet on an `UnreliableRemoteEvent`, so it no longer sits in the same queue as `PlaceBlock`.
- **The server** has no ghost parts any more, just a small record per player. 20 times a second it sends everyone one bundle with every ghost that changed, and once a second a full copy of all ghosts. The full copy repairs lost packets and fills in players who just joined.
- **Other players' ghosts** are drawn on each player's machine and glide toward each new cell instead of jumping. A jump of more than 8 cells, or a ghost reappearing, snaps straight there.
- **Server checks:** it rejects badly formed messages, ignores more than 30 messages a second from one player, and handles packets that arrive late or out of order.
- **Placing blocks** works exactly as before: `BlockPlacer`, `BlockPlacement` and `PlaceBlock` are untouched.

## Estimated traffic (12 players building, from the doc)
| | Before | After (worst case) |
|---|---|---|
| Each builder's upload | 1.7–7.0 KB/s (60–240 messages/s) | 0.4 KB/s (20/s) |
| Server receiving | 21–84 KB/s, up to 2,880 messages/s | 4.8 KB/s, 240/s |
| Each player's download | up to 18 KB/s | 3.9 KB/s |
| Server sending | up to 216 KB/s | 47 KB/s |

Beyond the raw bytes, the old setup probably explains the ping you saw. At 240 FPS one player used about half of the roughly 500 messages a second Roblox allows each client. And because those messages had to arrive in order, every ghost update could hold up block placement and new blocks appearing for everyone.

## What players will notice (full list in the doc)
- Their own ghost keeps up with the cursor.
- Other players' ghosts glide between cells, trailing the cursor by about 50–150 ms plus ping.
- If a packet is lost just as someone stops moving, their ghost can sit in the wrong cell for up to about 1 second. After an upload outage of several seconds, it takes up to about 2 seconds to catch up.
- The server no longer has ghost parts; `Workspace.Ghosts` now exists only on each player's machine. Nothing else in the place used the server copies.

## Files
- `src/ReplicatedStorage/Shared/GhostWire.luau` (new): the shared module that reads and writes the ghost packets.
- `src/ServerScriptService/GhostPreview.server.luau` and `src/StarterPlayer/StarterPlayerScripts/GhostPreview.client.luau`: rewritten.
- `docs/perf/ghost-network.md` (new): the before and after estimates, how I worked them out, and what players will notice.
- `sourcemap.json`: regenerated for the type checker.

Nothing is committed.

## Still to do
- **Measure it.** Rerun the 12-player test and compare `Stats.DataSendKbps` and `DataReceiveKbps`, and data ping against network ping, with the old version. The doc says what to look for.
- **One untested assumption:** I assumed unreliable remotes add the same 9 bytes per message as normal remotes. That has only been measured for normal ones.
- **Tests:** the testing guidelines say to agree on what to test before writing any, so I didn't add any. I'd suggest one spec file for `GhostWire`:
  - a ghost lands in the same cell `BlockPlacement` would fill;
  - an unknown block type or an out-of-range cell hides the ghost;
  - a ghost packet comes back unchanged after being written and read, including a hidden ghost;
  - the server rejects packets of the wrong length or with an invalid block type;
  - a list of 70+ ghosts splits into bundles under the 1,000-byte limit and comes back unchanged;
  - sequence numbers still compare correctly after wrapping past 255.

  Say if you'd like that written.
- **Left alone on purpose:**
  - The server doesn't check that a ghost is near its builder, and the old code didn't either. Limiting it to the 64-stud placement reach would hide real ghosts, because the cursor ray reaches 512 studs.
  - Each ghost in a bundle carries an 8-byte player ID. A 1-byte slot number per player would cut each bundle by about 43%, but needs extra syncing.

  The new scripts also follow the existing files' `local` and `require(script.Parent…)` style rather than the style guide's `const` and path-string requires, to match the rest of the project.