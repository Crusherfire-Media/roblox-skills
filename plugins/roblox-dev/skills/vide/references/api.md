# Vide API reference

Checked against Vide **0.4.1** source and docs (github.com/centau/vide, docs at
centau.github.io/vide). Everything below also holds for 0.4.0 unless a version note says
otherwise.

## Contents

- Version notes
- Scope summary
- Creation: `create`, `action`, `changed`, `mount`, default properties
- Core reactivity: `root`, `source`, `derive`, `effect`
- Utilities: `cleanup`, `untrack`, `read`, `batch`, `context`
- Dynamic scopes: `show`, `switch`, `indexes`, `values`
- Animation: `spring`, animating a component, `step`
- Flags and types
- Writing your own dynamic scope helper

## Version notes

| Version | Change |
|---|---|
| Unreleased (main after 0.4.1, checked 2026-11-13) | Strict mode prints "attempt to yield in reactive scope" as a warning with a traceback and lets the thread finish, instead of erroring. Treat the warning as the same bug. |
| 0.4.1 | `create(class, props)` and `create(instance, props)` (two arguments) are deprecated. Use `create(class)(props)`. `create` types work in the new type solver without casts. |
| 0.4.0 | Builders of `show`, `switch`, `indexes`, `values` receive a `present` source and may return a removal delay. `show`'s builder receives the condition's value as a source. `cleanup` accepts threads. `spring` returns a second value, a control function. `false` children are ignored. `vide.defaults` flag added. A scope can no longer be destroyed while it is running. |
| 0.3.0 | `root` returns its destroy function first. `context` added. |

Read the running version from `Vide.version` (`{ major, minor, patch }`).

## Scope summary

| Function | Creates | Where it may be called |
|---|---|---|
| `root`, `mount` | Stable scope | Anywhere |
| `untrack` | Runs its function without tracking | Anywhere |
| `context(value, fn)` | Stable scope | Inside any scope |
| `effect`, `derive`, `spring` | Reactive scope | Inside a stable scope |
| `show`, `switch`, `indexes`, `values` | A reactive scope that watches the input, plus a stable scope per shown item | Inside a stable scope |
| `create` with a function property or child | A reactive scope per binding | Inside a stable scope |
| `create` with only plain values | Nothing | Anywhere |
| `cleanup` | Nothing; attaches to the current scope | Inside any scope |

No scope may yield. Strict mode turns a yield in a reactive scope into an error; a yield in a
stable scope (a component body) is not caught, but it still breaks scope tracking.

## Creation

### `create`

```lua
create(className: string): (props) -> Instance
create(template: Instance): (props) -> Instance -- clones the template, then applies props
```

How each entry of the props table is applied:

| Key | Value | Result |
|---|---|---|
| string `Parent` | Instance or function | Set last, after everything else. A function becomes a binding. |
| string | function, and the property is an event | Connected as a listener |
| string | function, and the property is not an event | Binding: an effect that sets the property |
| string | anything else | Property set |
| number | Instance | Parented to the new instance |
| number | function | Children binding: returns an Instance, an array of Instances, nested arrays, further functions, or `nil` |
| number | action | Run after events are connected |
| number | other table | Its entries are applied as if written in this table (after the outer table) |
| number | `false` or `nil` | Ignored |

Order: properties and children, then event connections, then actions (lower priority first),
then `Parent`.

A children binding unparents the instances it returned last time that it no longer returns, and
unparents all of them when its scope is destroyed.

Event connections are not tied to a scope; they last as long as the instance. A handler that
refers to its own instance keeps the instance alive, so pair it with `cleanup(instance)`.

In strict mode, setting the same property twice at the same nesting depth errors
(`duplicate property X at depth N`).

`vide.apply(instance)(props)` applies a props table to an existing instance without cloning. It
is undocumented and marked temporary in the source, so prefer `create(template)`.

### `action`

```lua
action(callback: (Instance) -> (), priority: number?): Action -- priority defaults to 1
```

Runs `callback` with the new instance, inside the current scope, after properties are set and
events are connected. Lower priorities run first. `cleanup` called inside the callback attaches
to the component's scope.

```lua
local function onVisibleChanged(callback: (boolean) -> ())
    return action(function(instance)
        cleanup(instance:GetPropertyChangedSignal("Visible"):Connect(function()
            callback(instance.Visible)
        end))
    end)
end
```

### `changed`

```lua
changed(property: string, callback: (value: any) -> ()): Action
```

An action (priority 1) that calls `callback` with the property's current value right away and on
every change, and disconnects when the scope is destroyed. Pass a source as the callback to
mirror a property into it: `changed("AbsoluteSize", size)`. `AbsoluteSize` and `AbsolutePosition`
are in real pixels, which differ from offsets under a `UIScale` (see `screens.md`).

### `mount`

```lua
mount(component: () -> T, target: Instance?): () -> ()
```

Runs `component` in a new stable scope (like `root`) and applies its result to `target` the way a
`create` child would, so a returned instance is parented to `target`. Returns the destroy
function.

### Default properties

Applied by `create(className)` before props, unless `vide.defaults = false`:

| Classes | Defaults |
|---|---|
| Frame, ImageLabel, ImageButton, TextLabel, TextButton, TextBox, ScrollingFrame, VideoFrame, ViewportFrame | `BackgroundColor3` white, `BorderColor3` black, `BorderSizePixel = 0` |
| TextLabel, TextButton, TextBox | `Font = SourceSans`, `Text = ""`, `TextColor3` black |
| TextButton, ImageButton | `AutoButtonColor = false` |
| TextBox | `ClearTextOnFocus = false` |
| ScrollingFrame | `ScrollBarImageColor3` black |
| ScreenGui, BillboardGui, SurfaceGui | `ResetOnSpawn = false`, `ZIndexBehavior = Sibling` |
| SurfaceGui | `SizingMode = PixelsPerStud`, `PixelsPerStud = 50` |
| UIListLayout, UIGridLayout, UITableLayout, UIPageLayout | `SortOrder = LayoutOrder` |
| Part | `Material = SmoothPlastic`, `Size = 1, 1, 1`, `Anchored = true` |

`create(template)` clones and applies no defaults.

## Core reactivity

### `root`

```lua
root(fn: (destroy: () -> ()) -> T...): (() -> (), T...)
```

Runs `fn` in a new stable scope and returns the destroy function plus whatever `fn` returned. If
`fn` errors, the scope is destroyed and the error is rethrown as `error while running root()`.
Calling destroy twice errors.

### `source`

```lua
source(initial: T): Source<T>
```

`s()` reads (and subscribes the running reactive scope). `s(value)` sets. Setting the value the
source already holds does nothing, except for a table that is not frozen, which always updates.

### `derive`

```lua
derive(fn: () -> T): () -> T
```

Runs `fn` in a reactive scope now and whenever a source it read changes, and caches the result.
Readers update only when the new result differs (`~=`), so a derive that builds a new table
updates readers every time. Use it over a plain function when several bindings read the value or
it is costly.

### `effect`

```lua
effect(fn: () -> ())
effect(fn: (previous: T) -> T, initial: T) -- receives what the last run returned
```

Runs `fn` in a reactive scope now and whenever a source it read changes. Scopes and cleanups
created during a run are destroyed before the next run.

## Utilities

### `cleanup`

```lua
cleanup(value: (() -> ()) | RBXScriptConnection | thread | Instance | { Destroy/Disconnect/destroy/disconnect })
```

Queues work for when the current scope reruns (reactive) or is destroyed (both kinds): a function
is called, a connection disconnected, a thread canceled, an Instance destroyed, an object's
`Destroy`/`Disconnect` (or lowercase) method called. Errors outside a scope.

### `untrack`

```lua
untrack(fn: () -> T): T
```

Runs `fn` so that sources it reads do not subscribe the running reactive scope. Effects created
inside it are allowed and are destroyed when the surrounding scope reruns.

### `read`

```lua
read(value: T | () -> T): T
```

Calls `value` if it is a function, otherwise returns it. Use it on props typed `T | () -> T`.

### `batch`

```lua
batch(fn: () -> ())
```

Runs `fn`, holding back effect reruns caused by its source writes until it returns, so an effect
that reads several of those sources runs once.

### `context`

```lua
local ctx = context(default)
ctx() -- get: the nearest value set above the current scope, or the default
ctx(value, fn) -- set: runs fn in a new stable scope where ctx() returns value, returns fn's result
```

The lookup walks up the scope that is running, so read a context in the component body. Event
handlers run outside any scope and get the default. To make a context value change over time, put
a source in it.

```lua
local themeContext = context(DEFAULT_THEME)

local function title(props: { Text: string })
    local theme = themeContext()

    return create("TextLabel")({
        Text = props.Text,
        TextColor3 = theme.TextColor,
    })
end

-- Inside a component body or a mount function:
themeContext(DARK_THEME, function()
    return title({ Text = "Settings" })
end)
```

## Dynamic scopes

Each of these must be called in a stable scope and returns a source of the instances it currently
shows; pass that source as a child. Every builder runs in its own stable scope, may return a
second value (seconds to delay destruction), and receives a `present` source that is `false` while
the builder runs, `true` once shown, and `false` again when the item is leaving. If the item
returns before its delay ends, destruction is canceled and `present` turns `true` again.

### `show`

```lua
show(condition: () -> any, builder: (value: () -> T, present: () -> boolean) -> (Instance, number?), fallback: ((present) -> (Instance, number?))?)
```

Shows `builder`'s result while `condition()` is truthy, otherwise `fallback`'s (or nothing).
`value` holds the latest truthy value of the condition, which suits "show details for the selected
item" (`show(selectedItem, function(item) ... end)`).

### `switch`

```lua
switch(key: () -> K)(map: { [K]: (present: () -> boolean) -> (Instance, number?) })
```

Shows the builder mapped to `key()`, or nothing when the key has no entry. Map values must be
functions.

### `indexes`

```lua
indexes(list: () -> { [K]: V }, builder: (value: () -> V, key: K, present: () -> boolean) -> (Instance, number?))
```

One row per key. A new key builds a row; a removed key destroys it; a changed value updates that
row's `value` source without rebuilding. Values are compared with `~=`, so an item table changed
in place does not update its row: give it a new table.

### `values`

```lua
values(list: () -> { [K]: V }, builder: (value: V, key: () -> K, present: () -> boolean) -> (Instance, number?))
```

One row per value. A new value builds a row; a removed value destroys it; a value that moved
updates that row's `key` source. Values must be unique (strict mode errors on duplicates). Suits
lists of objects that reorder (players, items, messages, notifications), and the `key` source can
drive position animations.

Choosing: both usually look the same. `values` avoids rebuilding rows when objects reorder;
`indexes` suits primitives and fixed keys.

## Animation

### `spring`

```lua
spring(target: () -> T, period: number?, dampingRatio: number?): (() -> T, (settings: { position: T?, velocity: T?, impulse: T? }) -> ())
```

Returns a source that moves toward `target()` like a physical spring, created in a reactive scope
(call it in a component body).

- `period` (default 1): seconds for one full swing if undamped.
- `dampingRatio` (default 1): above 1 approaches slowly, 1 arrives without overshoot, below 1
  overshoots, 0 never settles. Very large values error with `spring damping too high`.
- Springable: `number`, `UDim`, `UDim2`, `Vector2`, `Vector3`, `Color3`, `CFrame`, `Rect`, and
  arrays of up to four numbers. Not booleans or enums.
- The second return value jumps or pushes the spring: `control({ position = x })` snaps,
  `velocity` sets speed, `impulse` adds speed.

### Animating a component

Call `spring` in the component body with a function that returns the target, then bind its
result. The second argument is the period in seconds (default 1), the third the damping ratio
(default 1, no overshoot; below 1 overshoots).

```lua
local transparency = spring(function()
    return if isHovered() then 0 else 0.5
end, 0.2)

create("Frame")({
    BackgroundTransparency = transparency,
})
```

It springs numbers, `UDim`, `UDim2`, `Vector2`, `Vector3`, `Color3`, `CFrame`, and `Rect`, not
booleans or enums. For an exit animation, have the builder of `show`, `switch`, `indexes`, or
`values` return the seconds to wait after the instance, and animate from its `present` source,
which turns false when the item is leaving:

```lua
show(isOpen, function(_, present)
    local transparency = spring(function()
        return if present() then 0 else 1
    end, 0.3)

    return create("Frame")({
        BackgroundTransparency = transparency,
    }), 0.5
end)
```

`present` starts false and turns true right after the builder runs, so the same spring also
animates the entrance.

#### Motion style

Default to smooth, damped motion. Mark a change or an arrival with a fade, a highlight flash, a
glow, or a critically damped glide, and keep size and position free of overshoot, pops, and
elastic easing. It is a strong default, not an absolute rule, and it depends on the moment:
direct feedback to the player's own input earns a bounce (a button that sinks when pressed and
springs back up), while what the game changes on its own (arrivals, level-ups, counts, data
updates) moves smoothly. Use judgment between the two, and follow the project's own motion rules
where it has them.

### `step`

Springs and delayed destruction advance at 120 Hz from `RunService.Heartbeat`. Calling
`Vide.step(dt)` advances them by `dt` seconds and stops the Heartbeat driver, for projects that
drive Vide from their own loop.

## Flags and types

Set flags once, right after requiring Vide. Unknown keys error.

| Flag | Default | Meaning |
|---|---|---|
| `Vide.strict` | `true` unless Vide's module is compiled at O2. Live games always compile at O2, and Studio can too, so read the flag instead of assuming. | Extra checks: runs effects and derives twice per update, errors on yields in reactive scopes, duplicate `values()` entries, duplicate properties, and destroying a running scope; clearer error traces. Vide's docs recommend setting it explicitly for development, for example `Vide.strict = RunService:IsStudio()`. |
| `Vide.defaults` | `true` | Apply the default properties table |

Exported types: `Vide.Source<T>` (read and write function), `Vide.Context<T>`,
`Vide.Properties<T>`, `Vide.Instances`.

## Writing your own dynamic scope helper

Vide's dynamic scopes are built from public pieces, so a custom one follows the same shape:

```lua
local function showWhen(condition: () -> boolean, builder: () -> Instance)
    return derive(function()
        return if condition() then untrack(builder) else nil
    end)
end
```

`untrack` gives the builder a stable scope inside the derive, so it can create bindings, and the
derive destroys it on the next change. A helper that keeps several items alive across updates
(like `indexes`) creates one `root` per item instead, stores each destroy function, destroys
removed items itself, and registers a `cleanup` that destroys every item when the helper's own
scope ends.
