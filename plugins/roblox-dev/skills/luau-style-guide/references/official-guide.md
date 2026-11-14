# The Roblox guide and these rules

The Roblox Lua Style Guide (https://roblox.github.io/lua-style-guide/) takes
Google's C++ style guide as its model. This file sums up its guiding
principles in our words and lists every place these rules depart from it.
The examples throughout this skill are our own.

## Guiding principles

- A style guide exists to end formatting arguments, not to be "right". Accept
  the standard so review time goes to behavior instead of layout.
- Optimize for reading, not writing. Code is written once and read many
  times, including by you months later. Prefer layouts that produce clean,
  line-local diffs.
- Avoid magic. Surprising or dangerous language features (metatables above
  all) are pleasant until they break and nobody can tell why. Use them with
  care.
- Stay consistent with idiomatic Lua where it makes sense.

## Where these rules depart from it

The project's own `CLAUDE.md` wins wherever it overrides or tightens a rule
in SKILL.md. Known differences from the Roblox guide:

- Member casing depends on what the member is, where the Roblox guide uses
  `camelCase` for all of them: properties and dictionary keys are
  `PascalCase` (`Module.Foo`), methods called with a colon are `PascalCase`
  (`Module:Foo()`), and functions called with a dot are `camelCase`
  (`Module.foo()`). A method declared with a dot only to annotate the type
  of `self` is still a method and keeps `PascalCase`. A module that owns a
  system exposes methods, like a Roblox service; a library of helpers
  exposes dot functions, like `task` and `table`.
- `const` for services, dependencies (requires), and `LOUD_SNAKE_CASE`
  constants. Everything else stays `local` unless `const` makes a particular
  piece of code clearer. The Roblox guide predates `const`.
- A `--[[ ]]` block comment above a function only when it explains why, or
  documents a publicly exposed function (library APIs, object methods).
  Other functions get no comment.
- Requires use require-by-string (`@game/...`, `./Sibling`, `@self/Child`)
  in place of `script.Parent` instance paths. The Roblox guide predates
  require-by-string and writes `local Foo = require(script.Parent.Foo)`.
  SKILL.md's Requires section uses the require-by-string form.
- A `do` block that scopes throwaway setup puts `do` on the same line as the
  declaration (`local x do`). The Roblox guide puts `do` on its own line.
- Comments never contain em dashes.
- Every script starts with `--!strict`, and the file layout adds a types
  part after the constants. See File structure in `file-layout.md`.
- Inside a ModuleScript the table it returns is always `local Module = {}`
  ... `return Module`. The Roblox guide names it after the file. Consumers
  still name the required variable after the module instance.
- Loops use generalized iteration (`for key, value in t do`) in place of the
  Roblox guide's `ipairs` / `pairs` split. See Tables in SKILL.md.
- Metatables serve prototype classes and weak tables. Enums are exported
  string-literal types, not tables guarded by `__index`. See `classes.md`
  and Types in SKILL.md.
- Workspace comes from the `workspace` global, not `GetService`.
- Yielding functions end in `Async`, yielding work starts through the `task`
  library, and a Promise is a tool for where it helps rather than a default.
  The Roblox guide suggests `coroutine.wrap`, `delay`, and Promises. See
  Yielding in SKILL.md.
- Private members keep the casing they would otherwise have after the
  leading underscore (`self._Cache`), where the Roblox guide writes
  `_camelCase`.
