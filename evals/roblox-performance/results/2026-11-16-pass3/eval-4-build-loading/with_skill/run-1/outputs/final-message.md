I've rewritten loading and unloading in `src/ServerScriptService/Builds.server.luau`, and the write-up is in `docs/perf/build-loading.md`. I couldn't run Studio from here, so the timing isn't measured yet. The script passes stylua, selene and luau-lsp, and a review agent found no blockers. I fixed the two problems it did raise.

**What changed**
1. **Two thirds fewer instances.** Each block used to be three instances: the part plus `Owner` and `PlacedAt` value objects. It's now just the part. Owner ID, placed time and grid cell live in a server-side table instead. The owner check on removal now reads that table, and clients can't write to it, so the check is at least as strict as before. Placed time is still kept for every block, both loaded and newly placed. A 20k build now sends 20,000 instances to clients instead of 60,000, and 8 full builds use about 190 MB less server memory.
2. **Load and unload are spread across frames.** One shared queue does at most 600 blocks or about 4 ms of server time per frame, whichever comes first. The 600 cap also limits how much each client has to process in one frame, which was the `ProcessPackets` hitch.
   - Unloads run before loads, so a full server frees a plot quickly.
   - If one block step throws an error, the queue logs a warning and drops that job instead of stopping for good. That will matter once saves come from the DataStore.
3. **Properties are set before the part is parented**, so the property writes aren't each replicated.
4. **Unloading no longer reads 20,000 part positions.** The cells to free come from the table.

Placing and removing blocks work as before: same input checks, reach limit, placement rate limit and owner rule.

**What players will notice**
- A big build fills in over about a second after its owner joins, instead of appearing all at once after a two-second server freeze. When someone leaves, their build disappears over about a second.
- A block someone places in a plot while it's still loading keeps its spot, and the saved block for that cell is skipped.
- On a full server, a player who joins just as someone leaves waits briefly for that plot to clear. Before, they would have been given the slot straight away.
- `Owner` and `PlacedAt` no longer appear under blocks on clients. Nothing on the client read them. If the upcoming feature needs placed time on clients, set it as an attribute on the part before parenting it rather than bringing the value objects back.
- If 8 players with full builds join at once, builds load one after another, so the last one appears after roughly 8 seconds.

**Still to check**
- **Server capture:** take a MicroProfiler capture with the same test (one player with the 20k build joins, then leaves). The worst `Script_Builds` frame should be under about 10 ms.
- **Client capture:** check `ProcessPackets` on a phone with a published build. If either capture still shows spikes, lower `QUEUE_ALLOWANCE` or `MAX_BLOCKS_PER_FRAME`; if builds appear too slowly, raise them.
- **Before real saving ships:** `SavedBuilds.load` needs a `pcall` with retries, plus a flag that stops a plot from saving if its load failed. Otherwise an empty plot could overwrite a player's real build.

The first type check failed only because `sourcemap.json` was out of date and didn't list these scripts. I regenerated it with `rojo sourcemap`; it isn't tracked by git, so it doesn't show up as a change. Two commands were blocked by permissions here; neither affected the result.