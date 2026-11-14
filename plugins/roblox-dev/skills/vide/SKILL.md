---
name: vide
description: Vide (centau/vide), the reactive Luau UI library for Roblox - components, sources, derive, effect, scopes, create(), show/switch/indexes/values, springs, context, and cleanup, plus laying UI out across phones, tablets, monitors, and TVs. Load it before writing, editing, reviewing, or debugging any Vide UI; for any code that requires Vide or calls create, source, effect, root, or mount; when building a ScreenGui, BillboardGui, or SurfaceGui from code in a project that uses Vide; when UI has to fit different screens or devices (UI scaling, mobile or touch layouts, UI that overlaps, runs off the screen, or looks too small); and on errors such as "cannot create a new reactive scope inside another reactive scope". Load it even for a one-line UI change.
---

# Vide

Vide is a reactive UI library modeled on SolidJS. A component is a plain function that **runs
once** and returns instances. Values that change live in **sources**, and Vide updates only the
properties bound to them. This skill targets Vide 0.4.x.

The full API, with every signature, the default property list, and version differences, is in
[references/api.md](references/api.md). Read it before using a function or option this file does
not show.

How to make UI fit every screen, from a small phone to a TV, is in
[references/screens.md](references/screens.md).

## Before writing code

1. Find how the project requires Vide, and read the `version` table at the top of Vide's main
   module. If it is not 0.4.x, read the version notes in the reference before trusting this file.
2. Read the components the project already has, so you reuse them. Judge them by this skill:
   existing code shows where UI lives, not how to write it.
3. Where UI modules live, how they are required, and which module mounts the UI come from the
   project's architecture rules (load the `roblox-dev:game-architecture` skill when the project has one).
   This skill covers how Vide code behaves.
4. Match the project's style guide. Examples here call `create("Frame")({ ... })`; Vide's own docs
   write `create "Frame" { ... }`, which is the same call.
5. When the project uses UI Labs (it has a `.storybook` module), load the `roblox-dev:vide-ui-labs` skill
   too: every component and screen gets a story in the same change.
6. When the UI opens and closes often, keeps pages or tabs, holds hundreds of instances or a long
   scrolling list, uses a CanvasGroup, plays sounds, or is slow or flickers, load the
   `roblox-dev:vide-performance` skill too.
7. When the UI comes from a Figma design, load the `roblox-dev:figma-to-roblox` skill too.
8. When deciding what a screen shows, where its elements sit, or how it behaves for each input
   (a new HUD, menu, or flow, or a review of one), load the `roblox-dev:game-ui-design` skill too.

Examples assume the project's Vide module is required as `Vide`, with the functions they use
pulled out: `const create = Vide.create`, `const source = Vide.source`, and so on.

## Core ideas

| Idea | What it is | Made with |
|---|---|---|
| Source | A value that changes. Call it with no argument to read, with one to set. | `source(initial)` |
| Derived value | A function that reads sources. | A plain function, or `derive(fn)` to cache it |
| Binding | A function given to a property or as a child. Vide reruns it and applies the result whenever a source it read changes. | `create` |
| Effect | Code that reruns when a source it read changes. | `effect(fn)` |
| Stable scope | Runs once and never reruns. Component bodies run here. | `root`, `mount`, `untrack`, `context`, and each item built by `show`, `switch`, `indexes`, `values` |
| Reactive scope | Reruns when a source it read changes. | `effect`, `derive`, bindings, and the insides of `show`, `switch`, `indexes`, `values`, `spring` |
| Cleanup | Code that runs when its scope reruns or is destroyed. | `cleanup(value)` |

Scope rules cause most Vide errors:

- Everything reactive is created inside a scope, and the UI tree starts from one `root` or `mount`.
- A reactive scope is created only inside a stable scope. Calling `effect`, `derive`, `spring`,
  `show`, `switch`, `indexes`, `values`, or a component with bindings from inside an effect or a
  binding errors with "cannot create a new reactive scope inside another reactive scope".
- Destroying a scope destroys every scope created inside it and runs their cleanups.
- Scopes never yield.

## Rules

### Build UI inside `mount` or `root`

Components need a scope, so build them only inside a function passed to `mount` or `root`, never
at module top level or from an event handler. Mount once per UI tree from client code, and keep
the returned destroy function when the UI can go away. That scope's destroy leaves the mounted
instance parented, so such UI also calls `cleanup(gui)` on its root instance.

```lua
const Players = game:GetService("Players")

local function app()
    return create("ScreenGui")({
        Name = "App",

        counter(),
    })
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local destroyApp = mount(app, playerGui)
```

Waits go before `mount`, never inside it. When the project forbids yields in startup methods
(as `roblox-dev:game-architecture` does for `Init` and `Start`), move the wait and the `mount` into
`task.spawn`.

### A component runs once, so bind values that change

Reading a source in the component body reads it once. Give the property a function instead. A
source is itself a function, so it can be passed directly.

```lua
local function coinLabel(props: { Coins: () -> number, IsOpen: () -> boolean })
    return create("TextLabel")({
        Text = function()
            return `Coins: {props.Coins()}`
        end,
        Visible = props.IsOpen,
    })
end
```

``Text = `Coins: {props.Coins()}` `` would show the first value forever. A function given to an
event (`Activated`, `MouseEnter`) is connected as a listener instead of bound.

### Components take one `props` table and return an instance

Components are ordinary local functions and follow the project's naming for them; these examples
use camelCase functions and PascalCase prop keys. Type a prop that may be fixed or changing as
`T | () -> T` and pass it straight into `create`, which handles both. Use `read(props.X)` inside
a binding when you need the value itself.

```lua
type ButtonProps = {
    Text: string | () -> string,
    Activated: () -> (),
}

local function button(props: ButtonProps): TextButton
    return create("TextButton")({
        Size = UDim2.fromOffset(200, 50),
        Text = props.Text,
        Activated = props.Activated,

        create("UICorner")({}),
    })
end
```

Reusable components receive everything through props (data, sources, callbacks), so they work
anywhere. Screen-level components are the ones that connect to game state.

State placement:

- UI-only state (hovered, open tab, typed text): a `source` created inside the component.
- State several components share: created by their common parent and passed down as props.
- Game state: owned by a game module. With Charm, load the `roblox-dev:vide-charm` skill.
- Facts about the screen (its size, the primary input): sources in one shared module.
  Screen-level components read it and pass layout variants down as props. See "Lay out for the
  screen the player has".

### Children

Number keys in a `create` table are children:

- An instance is parented.
- A function or source is a children binding: return an instance, an array of instances, or
  `nil`, and Vide parents and unparents them as the result changes.
- A nested table is applied as if written inline, so a component can splice in a group of
  properties or an array of children.
- `false` and `nil` are skipped, so `props.HasFooter and footer({})` is a valid child that is
  decided once.

### Derive values; keep effects for side effects

Compute values from sources with a plain function, or with `derive` when several bindings read
it or it is costly. `derive` caches the result and updates readers only when it changes.

```lua
local total = derive(function()
    return price() * quantity()
end)
```

Use `effect` only for work a binding cannot express: calling a method, logging, driving a
non-Vide object. Keep derives and effects pure: they read sources and never set them. Setting a
source from an effect to feed another source is what `derive` is for, and doing it by hand can
loop forever. Strict mode runs every effect and derive twice per update to catch impure code, so
trigger one-shot actions such as sounds from event handlers.

### Swap UI with `show`, `switch`, `indexes`, `values`

These create and destroy parts of the UI as sources change. Each returns a source holding the
current instances; pass it as a child.

```lua
local isOpen = source(false)
local page = source("Shop")

create("ScreenGui")({
    button({
        Text = "Menu",
        Activated = function()
            isOpen(not isOpen())
        end,
    }),

    show(isOpen, function()
        return menu({})
    end),

    switch(page)({
        Shop = function()
            return shopPage({})
        end,
        Inventory = function()
            return inventoryPage({})
        end,
    }),
})
```

Building a component inside a binding or an effect errors (a reactive scope inside a reactive
scope) and rebuilds it on every update; these four functions are the way to swap UI. `show`
passes its builder `(value, present)`, so wrap components that take props in a function as above.

For lists, pick by what the table holds:

- `values(list, builder)` for tables of unique objects that may reorder (players, inventory
  items, messages). The builder gets `(item, index)`, where `index` is a source.
- `indexes(list, builder)` for everything else, especially primitives or fixed keys (stats). The
  builder gets `(value, key)`, where `value` is a source.

```lua
values(players, function(player, index)
    return playerRow({
        Name = player.DisplayName,
        LayoutOrder = index,
    })
end)

indexes(stats, function(value, key)
    return statRow({
        Label = key,
        Value = value,
    })
end)
```

Builders return an instance. `values()` needs every value to be unique; strict mode errors on
duplicates.

### Replace tables instead of changing them

A source updates when it is set, not when a table inside it changes. Build a new table and set
it. Give a changed item a new table too, and keep unchanged items as they are so `values()` keeps
their rows.

```lua
local nextItems = table.clone(items())
table.insert(nextItems, newItem)
items(nextItems)
```

Setting a source to the value it already holds does nothing, except for tables that are not
frozen: those always update.

### Clean up what Vide does not own

Connections to outside signals, spawned threads, and objects a component creates end with the
component only when registered with `cleanup`. It accepts a function, a connection, a thread, an
Instance, or anything with a `Destroy` or `Disconnect` method.

```lua
local function clock()
    local now = source(os.time())

    cleanup(RunService.Heartbeat:Connect(function()
        now(os.time())
    end))

    return create("TextLabel")({
        Text = function()
            return os.date("%H:%M:%S", now())
        end,
    })
end
```

Events set through `create` last as long as their instance and need no cleanup. Instances need
no `Destroy` either: a children binding unparents UI it stops returning, and the garbage collector
frees it (mounted roots excepted, see above). Another exception
is an event handler that refers to its own instance, which keeps the instance alive; add
`cleanup(instance)` in that component.

### Keep yields out of scopes

Component bodies, bindings, effects, and derives never yield: no `task.wait`, `WaitForChild`,
`InvokeServer`, or `...Async` calls. Event handlers run outside scopes and may yield. To load
data when a source changes, spawn a thread from an effect and clean it up, so a newer change
cancels the older request:

```lua
effect(function()
    local itemId = selectedItemId()
    local thread = task.spawn(function()
        itemDetails(fetchItemDetails(itemId))
    end)
    cleanup(thread)
end)
```

### Animate with `spring`

Call `spring` in the component body with a function that returns the target, then bind its
result. Read "Animating a component" in `references/api.md` before writing an animation: it has
the arguments, what can spring, how entrance and exit animations use the `present` source, and
the default motion style: smooth and damped, with a bounce kept for direct feedback to the
player's own input.

### Share values down the tree with `context`

`context(default)` passes a value (often a theme or a source) to every component built inside it
without threading props. Read it in the component body and keep it in a local: event handlers
run outside scopes, where a context returns its default. An example is under `context` in
`references/api.md`.

### Lay out for the screen the player has

The same UI runs on a phone, a tablet, a monitor, and a TV, and the player can change the window
or the input while it is up. [references/screens.md](references/screens.md) has the method, the
numbers, the screen module, and the traps. Read it before laying out a HUD, a modal, or a
full-screen panel, and whenever UI overlaps, runs off the screen, or reads too small somewhere.
In short:

- **Read the screen from one module, as sources.** The viewport size, the topbar inset, and the
  primary input live in one shared module, and layout binds to them. A value read once goes wrong
  when the device changes, and the screen is not settled when startup code runs.
- **Grow the whole UI with one `UIScale` under every ScreenGui the game builds**, on screens
  whose short side is over the 1080 it was authored for. Smaller screens keep a scale of 1 and
  change layout. `AbsoluteSize`, `AbsolutePosition`, and `UITextSizeConstraint` limits stay in
  real pixels under that scale.
- **Give a reusable component its layout variant as a prop**, so the screen-level component
  decides and a story can show each variant.

### Keep every element on screen; change its state

Players learn what a screen can do from what it shows: an element that appears only once it
applies is one they never discover, and its absence leaves a hole or shifts its neighbors. Every
element keeps its place in every state:

- An action that can do less than its best stays enabled: a MAX that can buy one stage reads
  `MAX x1` and buys it.
- An action that can do nothing now is drawn disabled (grayed, no hover or press response) and
  says why: a hover tooltip on desktop, and the same text on press for touch.
- An empty list or section keeps its frame and says how to fill it.

Bind the disabled look, the reason, and the empty state to the condition. Keep `show`,
conditional children, and a state-bound `Visible` for UI whose subject this state lacks: an action
for another mode or another kind of item, or goals for a place that has none.

This covers UI you edit too: when an element you touch hides because it is unavailable, under a
threshold, or empty, make it stay if the task covers it, else tell the user.

### Build layouts that measure clean

A few habits cause most layout defects: square surfaces inside rounded frames, strokes and
scroll bars with no room left for them, text columns sized for the sample string, and gaps typed
twice. Read [references/layout-quality.md](references/layout-quality.md) before building a panel,
list, card, or row of tiles; it gives each habit and how to measure the result.

### Smaller tools

`changed` (follow a property such as `AbsoluteSize` or a TextBox's `Text`), `action`, `batch`,
`untrack`, and `create(template)` (clone a designer-made instance) are in `references/api.md`.

### Know Vide's defaults

Vide sets default properties on common classes: no borders and white backgrounds on frames,
buttons, and labels; `SourceSans` black text and empty `Text` on text objects;
`AutoButtonColor = false` on buttons; `ResetOnSpawn = false` and `ZIndexBehavior.Sibling` on
ScreenGuis, BillboardGuis, and SurfaceGuis; `SortOrder.LayoutOrder` on layouts. Set only what
differs. The full list, and the `vide.defaults` flag that turns them off, are in the reference.

### Develop with strict mode on

Strict mode runs effects and derives twice per update, errors on yields in reactive scopes, on
duplicate values in `values()`, and on duplicate properties, and prints clearer stack traces.
Vide turns it on by itself only when its module is not compiled at optimization level O2, and
Studio can compile at O2 too. So set it once, right after the project first requires Vide:
`Vide.strict = RunService:IsStudio()`. When that line is missing, add it there. When something
misbehaves only with strict mode on, the code is impure: fix the code.

## Common problems

When Vide prints an error, or UI misbehaves (a label never updates, an effect runs twice, memory
grows as a screen opens and closes, layouts mix or land off target on some screens), find the
message or symptom in [references/common-problems.md](references/common-problems.md).

## Verifying

Vide errors print `effect error stacktrace` or `error while running root()` with the failing
line. After a change, compile-check and type-check the module the way the project does. After
every UI change, run the story check from `roblox-dev:vide-ui-labs` on the stories that render
the UI, then measure the mounted result by "Measuring the result" in
`references/layout-quality.md`. Fix what they find, or tell the user why a finding stays. Without
UI Labs, run the UI in a playtest and measure its PlayerGui the same way. Search the output log
for those two phrases. After a layout change, check it on the screens `references/screens.md`
lists under "Checking the result". Whether the UI looks right is the user's call: list what they
should check on screen.
