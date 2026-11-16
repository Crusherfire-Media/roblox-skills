I made one code change, rejected the other five items, and wrote up the reasons in `docs/perf/placement-review.md`.

None of the six changes would make a difference you could notice. The rate limit means a server sees at most 80 placements a second, and only if all 8 players are spam-clicking at once. At that rate the placement code costs well under 1% of a frame. So for each item I asked whether it's worth doing for some reason other than speed.

| # | Suggestion | Verdict |
|---|---|---|
| 1 | Pool the Parts | **No.** Placed blocks are never destroyed, so a pool would never get a part back to reuse. |
| 2 | Pack arguments into a buffer | **No.** The message is already only a couple dozen bytes. A buffer would save maybe ten bytes per click and add hand-written decoding and validation to the server code that checks what clients send. |
| 3 | UnreliableRemoteEvent | **No, this would cause bugs.** Unreliable events can be lost in transit, so some clicks would place nothing, with no error, especially on poor connections. They suit data where the next update replaces the last one, like positions, not one-off actions like placing a block. |
| 4 | `--!native` | **No.** It speeds up heavy Luau calculations. These scripts are short event handlers that spend their time in engine calls, which it doesn't affect. |
| 5 | Lookup table instead of `table.find` | **Done, to simplify, not for speed.** The lookup table already existed: the server built a separate `VALID_NAMES` list for `table.find`, then looked the name up in `BlockTypes.ByName` anyway. Now it checks `ByName` and returns if the name isn't there. Behaviour is the same. |
| 6 | Create RaycastParams once | **No.** Creating it costs nothing measurable. The current code also reads your character fresh on every click. A cached copy would need updating every time you respawn, or after your first death you'd start placing blocks on yourself. It becomes worth doing if you add something that raycasts every frame, like a preview block that follows the mouse. |

The review also notes that the likeliest real cost later on is the number of placed blocks, since they pile up forever. That isn't on your friend's list.

The only code change is in `src/ServerScriptService/BlockPlacement.server.luau`. I couldn't run selene or StyLua on it because the session denied the command, so run your usual lint and format check before committing. Nothing is committed yet.