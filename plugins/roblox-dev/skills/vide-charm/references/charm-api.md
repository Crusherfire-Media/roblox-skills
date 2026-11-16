# Charm API reference

Checked against Charm **0.11** and vide-charm **0.4** (github.com/littensy/charm). Charm's
reactive core is adapted from alien-signals.

## Contents

- Terms
- State: `signal`, `atom`, `computed`
- Reacting: `effect`, `effectScope`, `listen`, `subscribe`, `observe`
- Utilities: `mapped`, `untracked`, `batch`, `trigger`, `onCleanup`
- Flags
- vide-charm
- Deep Charm (experimental)
- Migrating from Charm 0.10

## Terms

- **Getter**: a function that returns state. Signal getters, computed values, atoms, and any plain
  function that calls them all count, and Charm tracks the signals such a function reads.
- **Setter**: takes a new value, or an updater function `(current) -> next`. It notifies only when
  the value changes (`~=`, or a custom `equals`).

## State

### `signal`

```lua
local getCount, setCount = Charm.signal(0)
local getMax, setMax = Charm.signal(0, function(current, incoming)
    return incoming <= current -- true means "equal": skip the update
end)

setCount(1)
setCount(function(count)
    return count + 1
end)
```

Returns a getter and a setter. Reading the getter inside a Charm effect or computed subscribes it.
The updater function runs untracked and must not yield.

### `atom`

```lua
local count = Charm.atom(0)
count() -- read
count(5) -- set
count(function(n) return n + 1 end)
```

A signal whose getter and setter are one function. Accepts the same `equals` argument.

### `computed`

```lua
local getFullName = Charm.computed(function(previous)
    return `{getName()} {getSurname()}`
end)
```

A read-only getter that caches its result and recomputes only after a signal it read changes. It
is lazy: it recomputes when read. The getter receives its previous result (`nil` the first time).
Readers are notified only when the result differs (`~=`).

## Reacting

### `effect`

```lua
local dispose = Charm.effect(function()
    print(getCount())
    return function()
        -- runs before the next rerun, and on dispose
    end
end)
```

Runs now and again whenever a signal it read changes. It may return a cleanup function. Returns a
dispose function.

An effect created while another effect runs is **nested**: it is disposed and re-created each time
the outer effect reruns, and disposed with it. To create one that outlives the outer effect, create
it inside `untracked`.

### `effectScope`

```lua
local dispose = Charm.effectScope(function()
    Charm.effect(function() ... end)
    Charm.effect(function() ... end)
end, detached)
```

Collects every effect created inside the callback so one call disposes them all. The callback may
return a cleanup. With `detached = true`, the scope is not tied to a surrounding effect or scope.

### `listen`

```lua
local dispose = Charm.listen(getCount, function(count, previousCount)
    print(count, previousCount)
end)
```

Runs the callback now and whenever the getter's value changes. Only the getter is tracked; the
callback runs untracked, so effects created in it are not nested. A plain-function getter is wrapped
in a `computed`, so the callback fires only when its result changes.

### `subscribe`

Same as `listen`, but the callback does not run on creation, only on changes.

### `observe`

```lua
local dispose = Charm.observe(getItems, function(item, key)
    -- runs once per key when the key appears
    return function()
        -- runs when the key is removed, or on dispose
    end
end)
```

Runs the callback once for each key added to the table and cleans it up when the key is removed.
Effects created inside are disposed with the key. It follows keys, not values: a changed value
under an existing key does not rerun the callback, so read the current value through a getter
inside it (`getItems()[key]`).

## Utilities

### `mapped`

```lua
local getUpper = Charm.mapped(getNames, function(name, key)
    return string.upper(name) -- optional second return value: a new key
end)
```

A computed table built by transforming each entry. The transform reruns only for entries whose
value changed, and unchanged output entries keep their identity.

### `untracked`

```lua
local value = Charm.untracked(getCount)
Charm.untracked(function() ... end)
```

Calls the function without subscribing the running effect, and without nesting effects created
inside it.

### `batch`

```lua
Charm.batch(function()
    setName("Jane")
    setSurname("Doe")
end)
```

Applies the writes, then runs affected effects once.

### `trigger`

```lua
Charm.trigger(getArray)
```

Notifies subscribers of the signals the function reads, for a table that was changed in place.
Prefer immutable updates; with `frozen` on, the in-place change errors before `trigger` is reached.

### `onCleanup`

```lua
Charm.onCleanup(function() ... end, failSilently)
```

Adds a cleanup to the running effect or scope. Warns when there is none, unless `failSilently`.

## Flags

Set on `Charm.flags`.

| Flag | Default | Meaning |
|---|---|---|
| `strict` | On in Studio | Yields in effects, computed getters, setters' updater functions, and scopes error. Also enables CharmSync patch validation. |
| `frozen` | On in Studio | Deep-freezes tables stored in signals (tables with a metatable are skipped), so in-place changes error. |
| `trackInnerEffects` | `true` | Nest effects created inside effects. Turn off only to debug a migration. |

## vide-charm

```lua
local source = VideCharm.useSignalState(getter) -- also exported as useAtom
```

Returns a Vide source that starts at `getter()` and follows it through `Charm.listen`. The listener
is registered with Vide's `cleanup`, so it must be called inside a Vide scope and stops when that
scope is destroyed. A plain-function getter acts as a selector: the source updates only when its
result changes.

## Deep Charm (experimental)

Deep Charm's `reactive(table)` wraps a mutable table in a tracking proxy, returning the proxy and an
update function that passes the raw table for changes (`table.insert` does not work on the proxy).
Its docs mark it experimental with a changing API, so use plain signals with immutable updates
unless the project already relies on it.

## Migrating from Charm 0.10

| 0.10 and older | 0.11 |
|---|---|
| `peek(getter)` | `untracked(getter)` |
| `atom(value, optionsTable)` | `atom(value, equalsFn)` or `signal(value, equalsFn)` |
| `computed(fn, secondArgument)` | `computed(fn)`; the getter receives the previous value for custom checks |
| `effect(function(cleanup) ... end)` | `effect(function() ... return cleanupFn end)` |
| Effects created inside effects were independent | They are nested and disposed with the outer effect (`untracked` opts out) |
| CharmSync syncer objects | CharmSync `server` and `client` modules (see charm-sync.md) |
| Tables not frozen | Frozen in Studio (`frozen` flag) |
