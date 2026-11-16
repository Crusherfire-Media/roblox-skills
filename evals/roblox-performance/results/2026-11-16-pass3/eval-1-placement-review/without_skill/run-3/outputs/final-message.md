I made one of the six changes. The other five aren't worth doing at this scale, and one of them would break placement. My reasoning for each is in `docs/perf/placement-review.md`.

**The load:** at 10 blocks a second each and 8 players, the server handles at most 80 placements a second. That's a tiny fraction of one frame, so none of these suggestions could fix a slowdown a player would notice.

| # | Suggestion | Verdict |
|---|---|---|
| 1 | Pool the Parts | **No.** Blocks are never destroyed, so there's nothing to put back in a pool and reuse. |
| 2 | Pack arguments into a buffer | **No.** It would save a few bytes per placement, but the server would have to decode data an exploiter controls, and that's easy to get wrong. |
| 3 | Switch to UnreliableRemoteEvent | **No, this would break things.** Unreliable events can drop messages, so some clicks would silently place nothing. The client also checks that the remote is a `RemoteEvent`, and an `UnreliableRemoteEvent` isn't one, so that check would fail on start. |
| 4 | Add `--!native` | **No.** Nearly all the time goes to engine calls (`Instance.new`, setting properties, `Raycast`, `FireServer`), and native mode doesn't speed those up. |
| 5 | Use a lookup table instead of `table.find` | **Done, to simplify the code.** Speed doesn't matter here: it only searched a list of 5 names. The useful part is that a lookup table already existed (`BlockTypes.ByName`). The server was building a separate `VALID_NAMES` list just for this check, so I removed it and the handler now checks `ByName` once. Behaviour is unchanged. |
| 6 | Create RaycastParams once | **No.** Making it per click costs almost nothing. A shared one would have to be updated every time the player respawns, or it would stop excluding their current character. |

The only code change is in `src/ServerScriptService/BlockPlacement.server.luau`. I couldn't run selene or stylua because the session blocked the command, so the edit hasn't been linted, format-checked or tested in Studio. If lag ever does show up, the doc suggests starting with the MicroProfiler: the cost of having lots of placed Parts will matter far more than this handler.