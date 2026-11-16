# Vide evals (M12 pilot)

Four tasks and a trigger set for the `vide` skill. Every task starts from the sandbox plus the
block placement fixtures in `tasks/fixtures/shared/`: `BlockTypes` (the five block types),
`BlockPlacement.server.luau` (validates and places blocks), and `BlockPlacer` (client: click or
tap to place, number keys 1 to 5 to select, `BlockTypeChanged` event). How to run them is in
`../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `block-picker` | Building the hotbar from scratch: `mount`/`root` once, a reusable tile component fed from `BlockTypes.List`, a bound highlight that also follows the number keys, `cleanup` on the outside `BlockTypeChanged` connection, no yields in scopes, and touch-friendly placement. |
| `fix-picker` | Fixing a picker with planted bugs (`tasks/fixtures/fix-picker/`). Reported: the outline reads the selection once; the hover card is built inside a children binding (the nested reactive scope error); an `InputBegan` connection with no `cleanup` stacks up; destroying the `root` leaves its ScreenGui in PlayerGui. Unreported, under "anything else": a `WaitForChild` inside the `root` and an `effect` that writes a source where a derived value belongs. |
| `picker-screens` | Making a desktop-only picker (`tasks/fixtures/picker-screens/`) fit phones, tablets, and large monitors: live screen state in one shared module, one root UIScale that grows but never shrinks below 1, a layout change on small screens, `PreferredInput` over `TouchEnabled`, staying clear of the touch controls, and a `UITextSizeConstraint` cap that has to scale. |
| `picker-motion` | Adding motion to a working picker (`tasks/fixtures/picker-motion/`): springs created in component bodies, an exit slide through `show`'s removal delay and `present` source, no breakage when build mode is toggled quickly, a highlight positioned in UI units under a UIScale above 1, and press feedback. |

Checks on `fix-picker` confirm each planted pattern is gone. The other checks are sanity checks
(Vide required, `mount` or `root` used, no `Instance.new("ScreenGui")`, a live screen size
listener, `spring` used). Motion style (overshoot, durations) is left out of the rubric as taste.

## Notes

- Fixtures live under `tasks/` because `setup_files` paths resolve from the task file's folder
  and may not contain `..`.
- The sandbox's `selene.toml` is `std = "roblox"` with default lints, so `mixed_table` warns on
  every Vide `create` table (properties and children in one table) and selene exits 1. The Vide
  fixtures start with `--# selene: allow(mixed_table)` so they pass; trial code that lacks it
  fails the selene check.
- `triggers.json` holds 10 queries that should load the skill and 10 near misses (Roact,
  react-lua, Fusion, plain Instance UI, Charm without UI, UI Labs controls, engine-level UI
  profiling, SolidJS, Iris, a camera spring). The react-lua scaling query is labeled false because
  the skill is about Vide, even though the description's device-layout clause is not limited to
  Vide.
