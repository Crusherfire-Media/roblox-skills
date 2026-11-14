# File layout

How a script is laid out: the header, the order of its parts, and how to
group code below the top level. Section banners for the top-level parts are
defined in the `roblox-dev:code-comments` skill.

## File structure

Order the contents of a file like this, skipping parts that do not apply:

1. The script header, always present and always first. The Roblox guide
   treats a file comment as optional and leaves author and date to version
   control; here both are required:

   ```lua
   --!strict
   --@author: #Author
   --@date: #Date
   --[[@description:

   ]]
   ```

   `--!strict` puts the whole file under strict type checking. When creating
   a script, replace `#Author` with the author's name and `#Date` with the
   creation date, matching the format used in neighboring scripts, and write
   what the file is for on the lines inside the description block. Leave an
   existing script's author and date alone when editing it.
2. Services, fetched with `game:GetService` into `const` bindings and sorted
   alphabetically. Workspace is the exception: use the `workspace` global.
3. Dependencies: `const` module imports via require-by-string.
4. Types: `type` and `export type` definitions, plus any module imported
   purely for its types.
5. Module-level `LOUD_SNAKE_CASE` constants, also `const`.
6. Module-level variables and functions.
7. The main section: the object the module returns, or the top-level logic
   that runs when a Script starts.
8. The `return` statement.

A module required only for its types belongs with the types (part 4), after
the other dependencies.

## When a file grows too large

A file that seems to need sections inside its sections is asking to be
split:

- Give nested classes and standalone helpers files of their own, kept out of
  the module's public API. Smaller files are also easier to test on their
  own.
- Check whether a library the project already uses covers the job before
  writing it again.

## Grouping below the top level

For grouping below the top level, use these instead of a section comment:

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
- Lean on placement. Part 6 of the file structure sets no order inside
  itself, so declaring a cluster of state just above the functions that read
  it makes the pair read as a unit.
