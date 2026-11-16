I fixed all three bugs. One other place was using Charm wrong, and fixing it also fixed a fourth bug you hadn't reported. StyLua and selene pass on both files. luau-lsp shows no errors in them; its only errors come from inside the Vide and Charm packages. I haven't run it in a playtest, so the behavior still needs checking in Studio.

**"Blocks placed" stuck at 0** (`PlacedBlocks.luau`)
`onBlockPlaced` added the new block to the existing history table and then stored that same table again. Charm only notices a change when it gets a different table. In Studio it also locks stored tables, which is why you saw "attempt to modify a readonly table" there. On live servers the change was silently ignored. Placing a block now stores a copy of the list with the new block added. `clear()` had the same problem and now just stores an empty list.

**"Last:" always "none"** (`BuildHud.luau`)
The label read the Charm value directly inside its text function. Vide can't see Charm changes, so the label kept its first value forever. It now goes through `useSignalState`, the same way the count already did.

**One extra click every time you toggle with H** (`BuildHud.luau`)
Every time the HUD was shown it started a new sound listener, and hiding it never stopped the old one. The listener is now registered with Vide's `cleanup`, so it stops when the HUD hides.

**Also fixed:**
- **No click when placing the same block type twice.** The sound only played when the last block type changed. It now plays whenever a block is added to the history, and Clear stays silent.
- **One value tracked in two places.** "Last placed" was stored separately from the history and had to be updated alongside it. It's now worked out from the last item in the history, so the two can't disagree.

**What to check in a playtest:**
- The count goes up with each block, and "Last:" shows the latest type.
- Placing the same type twice clicks both times.
- After pressing H several times, each block clicks once.
- Clear resets both lines to 0 and "none".

**Left alone:**
- **No UI Labs story for the HUD.** The project has the package but no stories, and adding one would mean splitting the HUD into separate display and data parts. I'll do that if you want.
- **Vide strict mode is off.** `Main.client.luau` never sets `Vide.strict = RunService:IsStudio()`. With it on, Studio would warn you sooner about mistakes in the UI code.

I also tried to run a combined format, lint, and type check, but this session can't approve that kind of command. I ran each check separately instead, with the results above.