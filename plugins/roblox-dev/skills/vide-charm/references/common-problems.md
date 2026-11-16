# Common problems

Charm-with-Vide messages and symptoms, their cause, and the fix.

| Symptom or message | Cause | Fix |
|---|---|---|
| A label shows the first value and never updates | A Charm getter read directly in a Vide binding | Bridge it with `useSignalState` |
| "cannot cleanup outside a stable or reactive scope" | `useSignalState` called outside `mount` or `root` | Call it in the component body |
| "attempt to modify a readonly table" in Studio | A Charm table changed in place | Copy, change, and set a new table |
| Works in Studio, stops updating in the live game | A Charm table changed in place (not frozen live, so no error) | Copy, change, and set a new table |
| A list row rebuilds on every update | The selector or state builds new tables for unchanged items | Keep unchanged items as the same tables; build shared shapes with `Charm.mapped` |
| Code keeps running after the screen closes | A Charm effect, `listen`, or `observe` without `cleanup` | Wrap its disposer in Vide's `cleanup` |
| A client-side change snaps back | The UI wrote a CharmSync signal | Ask the server to make the change |
| "Attempted to yield in an effect or scope" | A yield inside a Charm callback | Move the yielding work out of the callback |
