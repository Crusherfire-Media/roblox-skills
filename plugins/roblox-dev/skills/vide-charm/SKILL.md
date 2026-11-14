---
name: vide-charm
description: Charm (littensy/charm) reactive state used with Vide UI - Charm signals and computed values as game state, the vide-charm bridge (useSignalState), selectors, immutable table updates, and CharmSync server-to-client data. Load it together with the roblox-dev:vide skill whenever Vide UI reads or writes Charm state; when adding a Charm signal, computed, or store module that UI will display; when wiring CharmSync data into UI; and when a Vide label stops updating after a Charm signal changes.
---

# Vide with Charm

Charm holds game state in **signals**; Vide draws UI from **sources**. They are separate reactive
systems: a Vide binding or effect does not notice a Charm read, and a Charm effect does not notice
a Vide read. The **bridge** between them is `useSignalState` from the vide-charm package, which
turns a Charm getter into a Vide source.

This skill targets Charm 0.11 and vide-charm 0.4. The `roblox-dev:vide` skill's rules still apply; load it
too. Charm's full API and migration notes are in
[references/charm-api.md](references/charm-api.md), and server-to-client sync is in
[references/charm-sync.md](references/charm-sync.md).

## Before writing code

1. Find the project's Charm, vide-charm, and CharmSync modules and how they are required. Charm
   0.11 exports `signal`, `listen`, and `untracked`; a Charm that exports `peek` instead is 0.10
   or older, so read the migration notes in the reference first.
2. Find the module that owns the state the UI needs. The UI reads from it and asks it for
   changes; it does not create game state of its own.

Examples assume `Charm`, `VideCharm`, and `Vide` are the required modules, with Vide functions
pulled out as in the `roblox-dev:vide` skill.

## Who owns which state

| State | Where it lives | Examples |
|---|---|---|
| Game state that several systems or screens use | A Charm signal in the module that owns that data | Coins, inventory, quest progress |
| Server-owned data the client displays | A client Charm signal that CharmSync fills | Saved player data, round status |
| UI-only state | A Vide source inside the component | Hovered, open tab, typed text |

The owning module keeps its setter private, exposes the getter for reading, and exposes functions
that change the state, so every write goes through one place:

```lua
local Module = {}

local getCoins, setCoins = Charm.signal(0)

Module.getCoins = getCoins

function Module:AddCoins(amount: number)
    setCoins(function(coins)
        return coins + amount
    end)
end

return Module
```

## Rules

### Bridge every Charm read with `useSignalState`

Call `useSignalState(getter)` in the body of the component that connects UI to game state. It
returns a Vide source that follows the getter, and it unsubscribes when the component's scope is
destroyed. Pass the source down as a prop, so the view components below take plain props and can
have UI Labs stories.

```lua
local function coinLabel(props: { Coins: () -> number })
    return create("TextLabel")({
        Text = function()
            return `Coins: {props.Coins()}`
        end,
    })
end

local function coinDisplay()
    local coins = VideCharm.useSignalState(CoinService.getCoins)

    return coinLabel({ Coins = coins })
end
```

Reading `CoinService.getCoins()` inside the binding would show the first value forever, because
Vide only tracks Vide sources. `useSignalState` calls `cleanup`, so it only works inside a Vide
scope; call it once per value in the component body, not inside a binding or effect.

### Select only the slice a component needs

Pass a function to `useSignalState` to narrow a large table. The source updates only when the
selected value changes (compared with `==`).

```lua
local count = VideCharm.useSignalState(function()
    return InventoryService.getItems()[itemId] or 0
end)
```

Select primitives or tables that already exist in the state. A selector that builds a new table
every time updates on every change of its inputs. When several places need the same shaped
table, build it once in the owning module with `Charm.computed` or `Charm.mapped` (which keeps
unchanged entries as the same tables), and bridge that.

### Write through the owning module, from event handlers

UI changes game state by calling the owner's functions from event handlers such as `Activated`.
Bindings, derives, and effects only read.

```lua
Activated = function()
    InventoryService:EquipItem(itemId)
end,
```

### Treat Charm tables as immutable

Charm compares values with `==`, so changing a table in place notifies nobody. In Studio, Charm
deep-freezes every table stored in a signal (the `frozen` flag), so an in-place change errors
there; in live games it fails silently. Copy each level you change, then set:

```lua
setItems(function(items)
    local nextItems = table.clone(items)
    nextItems[itemId] = (nextItems[itemId] or 0) + 1
    return nextItems
end)
```

Leave unchanged nested tables as they are. Keeping their identity is what lets Vide's `values()`
keep their rows and lets selectors skip updates.

### Lists: bridge the table, then use Vide's list functions

Bridge the whole table and pass the source to Vide's `values()` or `indexes()`, following the
`roblox-dev:vide` skill's rules for choosing between them.

```lua
local pets = VideCharm.useSignalState(PetService.getPets)

values(pets, function(pet, index)
    return petCard({
        Pet = pet,
        LayoutOrder = index,
    })
end)
```

Charm's own `observe` also runs code per table entry; use it for non-UI work per entry (spawning
models, starting timers), and Vide's list functions for UI rows.

### Compute game values in Charm, UI values in Vide

A value that game systems also use (total damage, can the player afford this) belongs in a
`Charm.computed` in the owning module; the UI bridges it. A value only one piece of UI needs
(a formatted string, a color for a state) is a plain function or `derive` over the bridged source.

### Keep Charm effects out of components

Bridge the state and use Vide bindings instead. When a component truly needs a Charm `effect`,
`listen`, `subscribe`, or `observe`, register its disposer with Vide so it ends with the UI:

```lua
cleanup(Charm.subscribe(QuestService.getQuest, function(quest)
    playQuestSound(quest)
end))
```

Charm effects are not tied to Vide scopes, so without `cleanup` they keep running after the UI is
gone.

### Keep yields out of Charm callbacks

Charm effects, computed getters, updater functions, and `listen` callbacks never yield. In Studio
the `strict` flag turns a yield into an error.

### Batch several Charm writes

Wrap several Charm writes in `Charm.batch(fn)`, so listeners, including every bridge, run once
after the last write.

### Server data comes in through CharmSync

The client's synced signals are the UI's data. The UI reads them through the bridge and never sets
them: the next patch from the server overwrites a client-side write. To change server data, the
UI asks the server through the project's remotes. Setup and caveats are in
[references/charm-sync.md](references/charm-sync.md).

## Common problems

When a label stops updating, a Charm table errors as readonly or works only in Studio, list rows
rebuild on every update, code outlives its screen, or a client-side change snaps back, find the
message or symptom in [references/common-problems.md](references/common-problems.md).
