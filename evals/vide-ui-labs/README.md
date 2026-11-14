# vide-ui-labs evals (M12)

Four tasks and a trigger set for the `vide-ui-labs` skill. Every task starts from the sandbox plus
the block placement fixtures in `tasks/fixtures/shared/` (copied from `../vide/`). The UI Labs
utility package 2.4.2 is installed, but the plugin isn't and trials can't open a story, so every
task is judged from the story code, the component changes, and the checks. With-skill trials also
load `vide`. How to run them is in `../README.md`.

## Tasks

| Task | What it tests |
|---|---|
| `picker-story` | Writing a first story for a picker whose `Title` prop is a plain string read once: a valid Vide story table, a `Choose` built from `BlockTypes.List`, a title control that updates live (the component has to accept a source), tile clicks that move the highlight in the preview, and nothing that needs a running game. |
| `fix-story` | Fixing a broken story (`tasks/fixtures/fix-story/`). Reported: "Story module errored when required" from `Players.LocalPlayer.DisplayName` at the component's top level, a Show Names control that only applies on reload (read once in both the story and the component), and TileClick sounds piling up in SoundService (a Sound parented at require time). Hidden behind the first error: the story reads `props.controls.Selected` though the control sits in the `Block` group. |
| `group-controls` | Grouping and ordering a 13-control flat panel without changing what any control does: `Ordered` on every group and control, reads moved to the nested paths, and the `StoryProps` type updated. `ControlGroup`'s second argument is a trap: the TypeScript typing declares an order there, but the Luau function ignores it. |
| `hud-story` | Writing a story for a HUD whose body reads `LocalPlayer`, requires `BlockPlacer`, waits on a remote (a yield in a Vide scope), blurs Lighting, zooms the camera, and plays a sound. The fix splits data into props and keeps the world effects out of the story while the game keeps them. |

Checks on `fix-story` confirm each planted pattern is gone. `picker-story` and `hud-story` check
that a `.story` module hands UI Labs its Vide library and that no story requires `BlockPlacer`,
reads `LocalPlayer`, or waits. `group-controls` counts `Ordered` calls (13 controls plus their
groups). Hand-made answers for `picker-story`, `fix-story`, and `group-controls` passed luau-lsp,
selene, StyLua, and every check.

## Judge facts

The facts come from the utility package source: control conversion and `Ordered`, `ControlGroup`
ignoring a second argument in Luau, `Choose` and `Slider` errors, `Datatype` having only `Color3`,
`Environment` fallbacks, and the Vide story props (one source per control, nested groups,
`target`) from `src/Typing/Vide.d.ts`. Plugin behavior (how the controls panel sorts, which require
aliases resolve, what a reload re-runs) can't be verified from the sandbox, so no task's correct
answer depends on it, and prompts state the symptoms the user saw instead.

## Triggers

`triggers.json` holds 10 queries that should load the skill and 10 near misses. The description
asks for the skill "whenever you create or change a Vide component or screen", so two positives
are plain Vide UI changes with no mention of stories. The near misses are storybooks for other
libraries (react-lua in UI Labs, Hoarcekat, web Storybook), Vide questions that change no UI
(`indexes` versus `values`, how `cleanup` works), UI with no library, server Charm, Jest, Iris, and
plugin widget input.
