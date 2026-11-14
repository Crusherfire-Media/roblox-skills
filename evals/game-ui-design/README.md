# game-ui-design evals (M12)

Four tasks and a trigger set for the `game-ui-design` skill. Every task starts from the sandbox
plus the block game fixtures in `tasks/fixtures/shared/`: `BlockTypes` (ten block types),
`BlockPlacement.server.luau` (places blocks, and clears a player's blocks on `ClearMyBlocks`), and
`BlockPlacer` (client: click or tap to place, number keys 1 to 9 and 0 to select,
`BlockTypeChanged`, `setEnabled`, `clearMyBlocks`). How to run them is in `../README.md`.

The skill decides what UI shows, where, and how it behaves per input; `vide` writes the code. So
the tasks ask for Vide UI or a written review, and the rubrics score the skill's checkable claims
(touch target sizes, thumb and top bar zones, `Activated`, gamepad selection and Back, no
hover-only information, a second cue beside color, fixed text sizes, Roblox's accessibility
settings, safe destructive dialogs, off-platform links, pressure tactics), not taste.

## Tasks

| Task | What it tests |
|---|---|
| `inventory-screen` | Designing and building an inventory from `BlockInventory` (`tasks/fixtures/inventory-screen/`), plus a design note at `docs/inventory-screen.md`: a path for every action on touch, mouse and keyboard, and controller; default gamepad selection, contained focus, B to close; 44 px targets out of the thumb corners and the top bar; locked and empty states with a cue beside color and a locked press that still responds; details without hover; readable fixed text sizes. |
| `hud-review` | Reviewing a deliberately flawed HUD and daily reward popup (`tasks/fixtures/hud-review/`) into `docs/ui-review.md` without touching code. Planted: a blocking popup on join, a streak-loss countdown, a Discord link, menu buttons on the jump corner, a coin counter under the top bar (`IgnoreGuiInset`), `MouseButton1Click`, hover-only tooltips, no gamepad selection or Back, `TouchEnabled` for phones, 24 to 36 px buttons, `TextScaled` everywhere, color-only day states, 2.6:1 body text, an endless pulse, a 1.5 s toast. |
| `hud-platforms` | Adapting a PC-only HUD (`tasks/fixtures/hud-platforms/`) for phones, tablets, and Xbox: layout from `PreferredInput` (and `ViewportDisplaySize` for TVs), live; prompts that match the input (no keyboard hints on touch or gamepad, glyphs from `GetImageForKeyCode`); controller bindings for every HUD action; touch buttons for key-only actions, out of the thumb corners; the hover-only block name made visible; TV text sizes and edge margins. |
| `settings-menu` | Building a settings menu with music and effects volume and a "delete all my blocks" action (`GameAudio` in `tasks/fixtures/settings-menu/`): volume controls that work with a controller, a confirmation that names the loss with outcome-labeled buttons and the safe option focused, `PreferredTransparency` and `ReducedMotionEnabled` honored live, focus trapped in menu and dialog, B backing out in order, short motion. |

`hud-review` has `auto_checks: []` since it changes no Luau. The other checks confirm the
required files and the presence of the APIs the rubric hinges on (`Activated`, gamepad
selection, `PreferredInput`, a gamepad `KeyCode`, `PreferredTransparency`,
`ReducedMotionEnabled`), and that `MouseButton1Click` is gone from the PC HUD. Each check fails on
the untouched starting point and passes on a hand-made answer; every fixture passes luau-lsp,
selene, and StyLua.

## Judge facts

Every task adds one fact listing current engine APIs from the sandbox's `globalTypes.d.luau`
(`PreferredInput`, `ViewportDisplaySize`, `TopbarInset`, `PreferredTextSize`,
`PreferredTransparency`, `ReducedMotionEnabled`, `ScreenInsets`), so a judge doesn't mark them as
invented. The global facts already cover Vide's `ResetOnSpawn = false` default, which the settings
menu's "survives a respawn" criterion relies on.

## Triggers

`triggers.json` holds 10 queries that should load the skill (a crowded HUD, a screenshot critique,
gamepad menus, onboarding, accessibility options, tap target sizes, toasts, a layout experiment, a
level-up screen, a screen spec) and 10 near misses: Vide reactivity (`vide`), a UI Labs story
(`vide-ui-labs`), a Figma port (`figma-to-roblox`), UI profiling (`roblox-performance`), Jest specs
(`roblox-testing`), a purchase prompt (the skill puts shops and Robux sales out of scope), an API
design, a website, a jump-button gameplay bug, and image resizing.
