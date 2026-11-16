I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and it is now marked `--!strict`, but I couldn't confirm it actually passes strict type checking. The session blocked `luau-lsp` and `lune`, so I also couldn't run any tests comparing old and new behaviour. StyLua and selene both pass with no warnings or errors. Before merging, please run the `luau-lsp analyze` command from the README and some quick old-vs-new comparisons.

**What changed**
- **Types:** there are now exported `Block` and `Summary` types, and all four public functions are typed. Their names and arguments are unchanged.
- **Block data:** the old table `T` mixed the list of type names with the costs. It's now two tables, `BLOCK_TYPES` (the order) and `BLOCK_COSTS` (the prices). A comment says to add a new type to both.
- **Named numbers:** the unexplained numbers are now named constants: the half-height of 2, the bulk discount (over 50 blocks, ×0.9), the points for blocks, height and variety, and the bonus for using every type.
- **Number formatting:** the old `fmt(n, c, d)` was accidentally a global and took two boolean flags. It's now two local helpers, `formatWholeNumber` and `formatOneDecimal`, plus `addThousandsSeparators`, which still uses the same method of inserting commas.
- **Readability:** the deep nested `if`s are now guard checks, and short/long `format` share the "N blocks" part.

**Edge cases I kept on purpose**
- `getTallest` still returns *no values* (not an explicit `nil`) when nothing qualifies. There's a comment saying so.
- **A bug I kept:** in the old code, a block whose `Type` was a number from 1 to 5 passed the type check, because `T` also held the name list. `getTallest` returned such blocks, while `summarize` crashed on them. To keep `getTallest`'s results exactly the same, I moved that behaviour into one commented helper, `isTallestCandidate`, which only `getTallest` uses. If you agree nobody relies on it, you can delete that helper and use `isKnownBlock` instead.
- On a tie, the earlier block still wins. Height is still returned unrounded. Variety is still added to the text without formatting. `short` still works on any truthy value. The assert message in `summarize` is the same.

**Small differences, only for inputs that used to crash**
- `summarize` now skips numeric-`Type` blocks instead of crashing on them.
- When a number can't be formatted (NaN or infinity), the error message is clearer than before. It still errors, as it did.
- The global `fmt` no longer exists.

**For whoever extends this later**
- The +100 bonus now applies when a plot uses *every* type in `BLOCK_TYPES`. Today that's still 5 types, so scores are unchanged, but adding a sixth type raises the bar for the bonus.