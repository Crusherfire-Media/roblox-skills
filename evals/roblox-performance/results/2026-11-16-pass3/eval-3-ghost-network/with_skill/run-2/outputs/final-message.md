I've reworked the ghost previews, but nothing has been run in Studio yet. The traffic numbers in `docs/perf/ghost-network.md` are estimates built from known per-message byte costs, not measurements. Type checking, linting and formatting all pass. Block placement (`BlockPlacer.luau`, `BlockPlacement.server.luau`) is unchanged.

## What changed
- **Your own ghost** is now drawn on your client every frame. Before, it waited for a round trip through the server, so it lagged by your ping; now it moves with your cursor.
- **Sending**: the client only tells the server when its ghost changes (new cell, new block type, shown or hidden). It sends at most 20 times a second, whatever the frame rate. These go on a separate channel (an unreliable remote) instead of the one block placement uses. When nothing changes, the state is sent again after 0.3 s and then every 2 s, so a lost message fixes itself.
- **Server**: it no longer moves ghost parts that copy to every player. It just keeps each builder's latest ghost and sends the ones that changed to everyone in one message every 50 ms, split if it gets too big.
- **Other players' ghosts** are built on each client and glide toward each new cell. Jumps over 24 studs snap instead. A player who joins late gets every visible ghost once when they arrive.
- **New file**: the settings both sides share are in `src/ReplicatedStorage/Shared/GhostNetwork.luau`.

## Traffic estimate (12 players, all building)
| | Before | After |
|---|---|---|
| Upload per player at 240 FPS | 7.0 KB/s, 240 messages/s | at most 0.62 KB/s, 20 messages/s |
| Messages into the server | about 1,440/s, even when idle | 180–240/s while aiming, 6/s idle |
| Download per client, moderate cursor speed | 4.5 KB/s | 5.8 KB/s |
| Download per client, fast sweeps | up to 18 KB/s | at most 7.7 KB/s |

Download per client is about the same at normal cursor speed, slightly higher because each update now names the player and block type. The ping problem wasn't the amount of data. It was the number of messages, all queued in order on the same channel as block placement, so one delayed message held up everything behind it. That queue is now gone and every rate has a cap. The doc shows the working and suggests next steps if download ever needs cutting.

## What players will notice
- Your own ghost responds faster.
- Other players' ghosts glide between cells instead of jumping. They trail the builder's cursor by up to about 100 ms plus ping, instead of the old 300–400 ms backlog.
- Very fast cursor sweeps skip cells.
- Rarely, another player's ghost sits one cell off, or stays visible after they stop building. It usually corrects 0.3 s after they stop, and always within 2 s.
- The server no longer has the ghost parts in `Workspace.Ghosts`; they now exist only on each player's client. Nothing in the current code reads them.

A Roblox review agent flagged two problems, which I fixed. A message arriving just after a player left could leave their ghost data on the server forever. And losing both an update and its one follow-up copy left a ghost wrong for good, which is why the 2 s repeat exists.

One gap it raised that I didn't change: the server checks that a ghost's position is valid but not that it's within the 64-stud placement reach. A hacked client could put its ghost anywhere, for example in front of someone's camera. The old version had the same gap, and adding the check would hide ghosts aimed further than 64 studs away, so I've left that decision to you.

**To confirm the numbers:** run Test > Clients and Servers with 4 clients on the old and new versions, with everyone sweeping their cursor while in building mode. Compare each client's `Stats.DataSendKbps` and `Stats.DataReceiveKbps`, and check that data ping stays close to network ping. The doc's Verifying section has the full workload.