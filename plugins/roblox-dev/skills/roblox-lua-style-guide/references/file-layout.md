# File layout

How a script is laid out: the order of its parts, and how to group code
inside a part.

## File structure

Order the contents of a file like this, skipping parts that do not apply:

1. `--!strict` on the first line, which puts the whole file under strict
   type checking.
2. Services, fetched with `game:GetService` into `const` bindings and sorted
   alphabetically. Workspace is the exception: use the `workspace` global.
3. Requires: `const` module imports via require-by-string.
4. Module-level `LOUD_SNAKE_CASE` constants, also `const`.
5. Types: `type` and `export type` definitions, plus any module imported
   purely for its types.
6. Module state: the variables the module keeps between calls.
7. Private functions: the `local` helpers the rest of the file calls.
8. The public API: the table the module returns and the functions on it, or
   the top-level logic that runs when a Script starts.
9. The `return` statement.

One blank line separates the parts. Because every file follows the same
order, a reader finds the requires, the state, or the public API by position.

## When a file grows too large

A file that seems to need sections inside its sections is asking to be
split:

- Give nested classes and standalone helpers files of their own, kept out of
  the module's public API. Smaller files are also easier to test on their
  own.
- Check whether a library the project already uses covers the job before
  writing it again.

## Grouping below the top level

Group code inside a part with these:

- Put the group's description in the block comment of its first function.
  That comment still documents its own function, but it can also say what
  the group shares and which functions belong to it:

  ```lua
  --[[
  	The Place functions all check the target cell against the plot grid
  	and return false without placing anything when the cell is taken or
  	outside the plot.

  	PlaceBlock places a single block at a grid cell.
  ]]
  function Plot:PlaceBlock(cell: Vector3, blockId: string): boolean

  -- PlaceRow places blocks along one axis and stops at the first taken cell.
  function Plot:PlaceRow(start: Vector3, length: number, blockId: string): boolean
  ```
- Related variables can share a block comment the same way. Often a short
  note per variable, or a blank line between clusters, says enough; choose
  whichever leaves the clusters easiest to tell apart.
- Lean on placement. A `local` function has to be declared before any
  function that calls it is defined, so put each private helper just above
  its first caller. That also keeps the helpers of one job together.
