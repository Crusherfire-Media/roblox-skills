# Common problems

Vide errors print `effect error stacktrace` or `error while running root()` with the failing
line. Find the message or symptom below.

| Symptom or message | Cause | Fix |
|---|---|---|
| "cannot create a new reactive scope inside another reactive scope" | A component, `effect`, `derive`, `spring`, or `show` built inside a binding or an effect | Build it in the component body; swap UI with `show`, `switch`, `indexes`, `values` |
| "cannot use ...() outside a stable or reactive scope", "cannot cleanup outside a stable or reactive scope" | UI built outside `mount` or `root` | Build it inside the `mount` or `root` function |
| "attempt to yield in reactive scope" | A yield in a component body, binding, effect, or derive | Move it to an event handler, or `task.spawn` it and `cleanup` the thread |
| A label never updates | A source read once in the component body, a table changed but not set, or a Charm getter read directly | Bind a function, set a new table, or bridge Charm with the `roblox-dev:vide-charm` skill |
| Code in an effect runs twice per update | Strict mode | Expected; keep effects pure and fire one-shot actions from events |
| "a scope, that should rerun due to the update of a source, is already active" | An effect sets a source it read in the same run; `untrack` does not leave the effect's scope, so wrapping the write in it does not help | Set it from the event that caused the change, or from a deferred task that checks the condition again with `untrack` before writing |
| "cleanup error: ... cannot cancel thread" from an effect that defers work | `cleanup(task.defer(...))`, where the deferred work sets a source that reruns the same effect, so the rerun's cleanup cancels the thread that is running | Cancel the deferred thread in cleanup only while its `coroutine.status` is `"suspended"` |
| "duplicate property X at depth N" | The same property set twice in one `create` table | Remove one |
| "table source passed to `values()` contains duplicate values" | The same value twice in the list | Use `indexes`, or give each entry its own table |
| Memory grows each time a screen opens and closes | An outside connection without `cleanup`, or a handler that refers to its own instance | `cleanup(connection)` or `cleanup(instance)` |
| "spring damping too high" | Damping ratio too high for the period | Lower the damping or lengthen the period |
| UI shows a mix of two layouts, or the wrong one after the device changes | Layout chosen from a value read once, at build or at startup | Bind it to the screen module's sources (`screens.md`) |
| On a 1440p or 4K screen, text stays small while its box grew | `UITextSizeConstraint` limits are real pixels, which a `UIScale` does not change | Multiply the cap by the root scale, or use a fixed `TextSize` |
| An element placed from `AbsolutePosition` or `AbsoluteSize` lands off target on large screens | A real-pixel measurement written into an offset under a `UIScale` | Divide by the scale in effect there (`screens.md`) |
| Text spills out of its box when a panel shrinks on a phone | A minimum text size does not shrink with a `UIScale` | Stop shrinking at a floor and give the panel a compact layout |
| An element with `Rotation` draws unturned (its `AbsoluteRotation` reads 0) | A `UIListLayout` or `UIGridLayout` places it, and the engine ignores `Rotation` on the children a layout places | Rotate an image inside a plain Frame the layout places, or use art that already faces the right way |
| An automatically sized frame grows while an effect plays inside it, then snaps back | `AutomaticSize` on a frame with no layout measures every visible descendant, however deep, even inside a clipping frame or a CanvasGroup, so a ring or glow bigger than its surface stretches it | Put a `UIListLayout` on the automatically sized frame, or on the frame that holds the oversized piece: a frame with a layout counts only the children the layout places |
| A row of children sized `scale - offset` runs past its end | `UDim` offsets are whole numbers, so a fractional offset such as `-1.8` truncates to `-1` and every child comes out wider | Size the children 0 wide under a `UIListLayout` with `HorizontalFlex = Fill`, or keep offsets whole |
