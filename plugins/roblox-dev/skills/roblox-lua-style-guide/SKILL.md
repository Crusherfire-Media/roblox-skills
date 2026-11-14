---
name: roblox-lua-style-guide
description: Load before writing or editing any Roblox Luau, even a one-line fix - new scripts and modules, edits to existing scripts (as files or through a Studio MCP), and code you review or reformat - and whenever the user asks for clean code or the clean code skill. Load it once per session, before the first edit, alongside game-architecture or vide when those apply. Luau style rules based on Roblox's Lua style guide, written as agent rules, plus typing rules.
---

# Roblox Lua Style Guide

The rules here are summarized from the Roblox Lua Style Guide
(https://roblox.github.io/lua-style-guide/) and extended with rules of our own,
such as the Types section. Every rule is phrased as an instruction, and the
examples are labeled Good / Bad.

This file holds the rules every edit needs. Examples, reasons, and the rules
for less common work are in `references/`, under the same section names:

| Read | Before |
|---|---|
| [references/file-layout.md](references/file-layout.md) | Creating a script or module, or documenting a group of functions or variables |
| [references/classes.md](references/classes.md) | Choosing the shape of new state or a new kind of object, writing a class or metatable, or caching data by key |
| [references/formatting.md](references/formatting.md) | Wrapping a statement that does not fit in 100 columns, or an `if` expression that does not fit on one line; also the General whitespace examples |
| [references/examples.md](references/examples.md) | Writing a remote handler, requires inside or against a library, more than one block of requires, an enum branch that must handle every member, or a chain of async steps; or when how a rule applies is unclear |

Comment wording, section banners, and comment cleanup belong to the
`roblox-dev:code-comments` skill. Load it alongside this one.

## Precedence

The project's own `CLAUDE.md` wins wherever it overrides or tightens a rule
below. When a rule here seems to contradict the Roblox guide or habits from
it, [references/official-guide.md](references/official-guide.md) lists every
place these rules depart from that guide, plus the guide's guiding
principles. Everything else applies unchanged.

**Formatting tools.** When the project configures StyLua (a `stylua.toml` or
`.stylua.toml`), run it on the files you edit and keep its output. When it has
no formatter config, format by the rules below by hand, changing only the
lines your edit touches, so the diff stays about your change.

## File structure

Every script starts with this header, always present and always first:

```lua
--!strict
--@author: #Author
--@date: #Date
--[[@description:

]]
```

The rest follows in this order, skipping parts that do not apply: services
(`game:GetService` into `const` bindings, sorted alphabetically; Workspace
comes from the `workspace` global), dependencies, types, constants, module
variables and functions, the main section, and the `return`. Leave an
existing script's author and date alone when editing it. Read
`references/file-layout.md` before creating a script or module: it says how
to fill in the header and what belongs in each part.

## Requires

- Put every `require` above the rest of the code, so dependencies stay static.
- Bind each one with `const` and use require-by-string; never write
  `local Foo = require(script.Parent.Foo)`.
- Sort requires alphabetically by module name.
- A module required purely for its types goes in the types part of the file,
  after the other dependencies.

Relative paths resolve against the requiring script's parent:

- `./Foo` is a sibling of the requiring script.
- `../Foo` sits in the parent's parent.
- `@self/Foo` is a child of the requiring script.
- `@game/ServerScriptService/Foo` is an absolute path from the DataModel
  root. `@rbx` is the third alias.

Prefer relative paths within a project so it keeps working wherever it is
placed. Use `@game/...` for shared code at a fixed location, such as packages
under ReplicatedStorage.

Group requires into blocks that mirror the project's folder structure:
imported packages, then definitions pulled out of them, then the project's
own modules. The ordering rules for blocks and a worked example are under
Requires in `references/examples.md`.

## Classes, data, and metatables

Read `references/classes.md` before choosing between a class, plain typed
tables, arrays of plain data processed by one loop, and an entity component
system; before writing a class or using a metatable; and before caching data
by key. It holds composition, the `Destroy` rule, the prototype class
pattern, and weak tables, which cannot track Roblox Instances.

## General punctuation

- End statements without semicolons. A semicolon only earns its place
  between two statements sharing a line, and each statement gets its own
  line here.

## General whitespace

- Indent with tabs.
- Keep code lines under 100 columns, counting a tab as four. Prefer StyLua
  for enforcement.
- Wrap comments at 80 columns.
- Trim trailing whitespace.
- End the file with a newline.
- Align nothing vertically: one space on each side of `=`, whatever the
  neighboring lines do.
- Separate logical groups with one blank line. A block's first line is code,
  never a blank line.
- One statement per line, and function bodies on their own lines. An `if`
  whose body is only a `return`, `continue`, or `break` (a guard clause)
  still takes three lines: `if not plot then`, `return`, `end`.
- Put spaces around operators. Drop them only to show precedence:
  `local damage = base + bonus * 2^tier`.
- Follow every comma in tables and calls with a space.
- Keep opening syntax (`{`, `then`, `do`) on the same line as the statement
  that opens the block.
- Let a table's opening brace hug the line that starts it. When one call
  takes both a multiline table and a function, give each argument its own
  line instead.
- Expand a table over several lines once it holds more than two or three
  entries, or any nested table, even when it would fit. A short, flat table
  stays on one line.
- Wrap a statement that does not fit by the rules in
  `references/formatting.md`.

### if-then-else expressions

- Pick between two values with an `if ... then ... else` expression in place
  of `x and y or z`. It has no falsy-middle-value bug, it runs faster, and it
  reads as what it is.

  Good: `local price = if isOnSale then SALE_PRICE else BASE_PRICE`
  Bad: `local price = isOnSale and SALE_PRICE or BASE_PRICE`

  - For a default, use `or`: `volume or DEFAULT_VOLUME`, not
    `if volume then volume else DEFAULT_VOLUME`. Switch to an `if` expression
    when the value can legitimately be `false`, since `or` replaces `false`
    too.

- Keep each `if` expression small enough to sit on one line; a value that
  needs more logic gets a statement.
- An `if` expression that must span lines follows the rules in
  `references/formatting.md`; one that will not fit in three lines becomes a
  normal `if` statement.

## Blocks

- Write `if`, `while`, and `repeat` conditions bare, without parentheses.
- Test for a missing value with plain truthiness: `if not character then`.
  Write `== nil` or `~= nil` where it makes the condition clearer, such as
  when `false` is a meaningful value and only `nil` means "not set".
- When an `if` has an `else`, put the positive branch first:
  `if isReady then ... else ... end`, not
  `if not isReady then ... else ... end`. Guard clauses have no `else`, so
  this does not affect them.
- Use a `do` block when narrowing a variable's scope is useful. Put `do` on
  the same line as the declaration it feeds (`local nextOrderId do`). If the
  setup needs early-return guards, write a small function instead, since a
  `do` block cannot return early.

## Literals

- Quote strings with double quotes: `print("Can't afford that yet")`.
  - Use single quotes when the text itself holds double quotes:
    `print('Tap "Buy" to confirm')`.
  - When the text holds both, default to double quotes outside and decide
    case by case.

## Tables

- Give each table one kind of key: an array of values, or a dictionary.
- Loop over lists and dictionaries alike with generalized iteration:
  `for index, item in items do`, not `for index, item in ipairs(items) do`.
  Use `ipairs` only when a loop must stop at the first `nil` of an array
  with holes.
- Trailing commas in multiline tables, on every element.

## Functions

- Keep argument counts small, ideally one or two.
- Keep every call readable at the call site. Replace a boolean argument that
  switches behavior with two functions or a string enum parameter, and
  replace trailing optional arguments with an options table as the last
  parameter, typed with optional `PascalCase` keys
  (`options: { Anchored: boolean?, Color: Color3? }?`).
- Give a function one job. Keep loading and other side effects apart from
  calculation: `calculateRewards(profileData)` works on data that is already
  loaded, and `LoadProfileAsync` does the loading.
- Always call with parentheses, even for a single string or table argument.
- Declare named functions with function-prefix syntax, and make non-member
  functions `local`. A function whose definition is chosen by a condition is
  declared as a `local` first and defined in each branch.
- Functions in tables also use function-prefix syntax, with `.` or `:`
  matching the intended calling convention (see Naming) and `.new` for
  constructors.
- Return the same number of values from every path. When a function returns
  a value on some paths, end the others with `return nil`. A function that
  falls off its end returns no values at all, not `nil`, and zero values
  break calls that expect one: `tostring(f())` errors with "missing argument
  #1" and `table.insert(list, f())` with "wrong number of arguments".
- Call builtins through their library: `table.insert(items, sword)`, not a
  local alias such as `local insert = table.insert`.

## Types

Every script runs under `--!strict` (see File structure).

- Fully type every public function: each parameter and the return type.
  Public means another script can call it directly, such as a method or dot
  function on the module's returned table. Local helpers may rely on
  inference.
- Let inference type everything else. Annotate a local only when inference
  produces the wrong type or narrowing needs the annotation:
  `const MAX_HEALTH = 100`, not `const MAX_HEALTH: number = 100`.
- Type a map as `{ [K]: V? }` when it is read with keys that may be missing.
  Luau types a lookup in `{ [K]: V }` as `V` even for an absent key, so the
  missing case goes unchecked and errors at runtime instead.
- Put the `?` of an optional union around the whole union:
  `(boolean | () -> boolean)?`, not `boolean? | () -> boolean`.
- Write an enum as a union of string literals with `PascalCase` values, like
  Roblox `Enum` items: `export type Rarity = "Common" | "Rare" | "Epic"`.
  Export it from the module that owns it, a `<Name>Types` module when
  several modules share it, so every module checks against one definition.
- When a branch must handle every member of an enum, end the `if` chain with
  `exhaustiveMatch`, kept once in a shared utility library.

### Values from clients

Type every argument after `player` in an `OnServerEvent` or `OnServerInvoke`
handler as `unknown`, then narrow it with `typeof` and range checks that
also reject NaN, returning early when a check fails. Read Values from clients
in `references/examples.md` before writing such a handler.

## Comments

- Wrap comments at 80 columns.
- Use `--` line comments for inline notes. For several lines, use several
  line comments.
- Use `--[[ ]]` block comments for documentation: the `@description` block
  in the file header states the file's purpose, and a block comment above a
  function documents it. Write one only when it explains why the function
  exists or behaves the way it does, or when the function is publicly
  exposed (library APIs, object methods) and needs documentation. Other
  functions get no comment. Block comments are always expanded: `--[[`
  alone on the first line, text indented on the lines between, `]]` alone
  on the last line. The header's `--[[@description:` line is the one
  exception.
- Explain why, not what.
- Comments never contain em dashes.
- Section banners follow `roblox-dev:code-comments`, which owns that rule.

## Naming

- Spell words out in full.
- `PascalCase` for classes and type names.
- `PascalCase` for all Roblox APIs.
- Members of a table take their casing from what they are:
  - `PascalCase` for properties: dictionary keys, instance fields, and
    module-level values (`Module.Foo`, `Module.MaxStackSize`).
  - `PascalCase` for methods, declared and called with a colon
    (`Module:Foo()`, `ShopService:PurchaseItem()`). A method declared with a
    dot only to annotate the type of `self` is still a method and keeps
    `PascalCase`.
  - `camelCase` for functions declared and called with a dot
    (`Module.foo()`, `Module.formatPrice()`), including constructors such as
    `Module.new`.
  - Which one a module exposes depends on what it is. A module that owns a
    system (state, instances, a lifecycle) is interacted with through
    methods, the way Roblox services are (`Players:GetPlayers()`, so
    `PlotGrid:Build()`). A library of helpers with no system behind it
    exposes dot functions, the way `task` and `table` do (`task.wait()`,
    so `StringUtils.trim()`).
- `camelCase` for local variables, parameters, and local functions.
- End the name of a function that can yield with `Async`, keeping its usual
  casing: `ProfileService:LoadProfileAsync()`, `fetchDataAsync()`.
- Name a boolean as a yes/no question: `isFirstRun`, `hasShield`, `canJump`
  (`IsFirstRun` as a key). A field that mirrors a Roblox property keeps the
  property's name (`Enabled`, `Visible`).
- Name a function with a verb for what it does, as directly as possible:
  `increment`, not `plusOne`; `notify`, not `doNotification`; `wasCalled`,
  not `hasBeenCalled`.
- Name an event handler for when it runs: `onPlayerAdded`, `onTouched`.
- Name things in positive form: `isFlying`, not `isNotFlying`. When code
  only ever cares about the negative, name that instead: `isMissing`, not
  `not hasValue` everywhere.
- Inside a ModuleScript, the table it returns is always named `Module`
  (`local Module = {}` ... `return Module`), never after the file. Scripts
  that require the module still name the variable after the module instance.
- Capitalize only the first letter of an acronym inside a name:
  `playerJsonData`, `SendHttpRequest`. An abbreviation that stands for a set
  of letters keeps its capitals, as in `hexToRGB` or `ToHSV`.
- `LOUD_SNAKE_CASE` for constants, bound with `const`. Services and
  dependencies are `const` too. Everything else is `local` unless `const`
  makes a particular piece of code clearer.
- Mark a private member with a leading underscore, keeping the casing the
  member would otherwise have (`self._Cache`, `self:_Rebuild()`,
  `Module._helper()`).
- A ModuleScript's name matches what it exports. A module exporting a
  function `getPlotOwner` is a ModuleScript named `getPlotOwner`.

## Yielding

- The `Async` suffix (see Naming) makes every yield visible at the call site.
- Code that must return without yielding (module top-level code, `Init`,
  `Start`, Vide component bodies) hands yielding work to `task.spawn` or
  `task.defer`.
- A single yielding call stays a plain `Async` function. When to reach for a
  Promise or Future instead is under Yielding in `references/examples.md`.

## Error handling

A function that can fail reports it to the caller: it returns
`success, result`, returns a `Result` type, or uses an async primitive that
carries failure, such as a `Promise`. Raise an error only when the caller
broke the function's contract.

- When calling code that does throw, wrap the call in `pcall` and comment
  which errors you expect to handle. Pass a plain function to `pcall`
  directly, and wrap a method call in a function instead of the
  `pcall(part.Destroy, part)` shorthand.
- Give every `assert` a message, and keep it a constant string. When the
  message needs values, use an `if` with `error` instead:
  ``error(`Player has {gold} gold but needs {price}`)``.
- Assert what the type checker cannot see: ranges, non-empty strings, state.
  A `typeof` assert on a typed parameter only repeats its annotation. Data
  from clients follows Types > Values from clients instead.
- Leave `assert` out of hot paths: code that runs for many items every frame,
  or a loop a profile has named. Check the inputs once before the loop
  instead.

## General Roblox best practices

- Name a required module's variable after the module.
- Build a `UDim2` that is all scale or all offset with `UDim2.fromScale(x, y)`
  or `UDim2.fromOffset(x, y)`. Keep `UDim2.new` for values that mix both.
- Share state through the module that owns it. `_G` and `shared` bypass the
  type checker and hide which code writes the state.
