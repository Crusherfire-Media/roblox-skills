# UI Labs reference

Checked against the UI Labs plugin **1.6.1** source and docs (github.com/PepeElToro41/ui-labs, docs
at ui-labs.luau.page) and the utility package **2.4.2** (github.com/PepeElToro41/ui-labs-utils,
Wally `pepeeltoro41/ui-labs`). The docs' API pages are unfinished, so utility signatures below come
from the package source.

## Contents

- Story modules
- Vide story props
- Storybooks
- Controls
- Environment
- Plugin features worth knowing
- Plugin warnings

## Story modules

A ModuleScript whose name ends in `.story`. It returns either a function story or a table story.

Function story (any library): `function(target: Frame) ... return cleanupFunction end`. If it
errors before returning the cleanup, nothing gets cleaned up.

Vide table story:

| Key | Required | Meaning |
|---|---|---|
| `vide` | Yes | The Vide library. Its presence is what marks the story as a Vide story. |
| `story` | Yes | `(props) -> Instance?`, called once inside `vide.mount` into the preview frame |
| `controls` | No | Table of controls, keyed by the name shown in the controls panel |
| `summary` | No | Rich-text description shown in the story preview |
| `name` | Ignored | UI Labs always uses the module name |

`UILabs.CreateVideStory(info, story)` builds the same table (`info` holds `vide`, `controls`,
`summary`). It exists mainly for roblox-ts typing; a plain table works the same in Luau.

## Vide story props

| Key | Meaning |
|---|---|
| `props.controls` | One Vide source per control, updated when the control changes. A control group becomes a nested table of sources. |
| `props.target` | The preview frame. Parent to it and return `nil` instead of returning an instance. |
| `props.inputListener` | The same input signals as `Environment.InputListener` |

The story's scope is destroyed on unmount and before every reload, so `Vide.cleanup` in the story
runs then. On unmount UI Labs also calls `vide.step(0)`, which disconnects that Vide copy's spring
driver.

## Storybooks

A ModuleScript whose name ends in `.storybook`:

| Key | Meaning |
|---|---|
| `storyRoots` | Required. Array of instances searched for `.story` modules; subfolders become folders in UI Labs. |
| `name` | Display name; defaults to the module name. |
| `groupRoots` | When `true`, each `storyRoots` entry gets its own folder, and stories listed directly in `storyRoots` are included. |

Stories outside every storybook still show up, under "Unknown Stories".

## Controls

Literal values make primitive controls: a string, a number, a boolean, or a `Color3`. The utility
package builds the rest (`UILabs = require(<utility package>)`):

| Constructor | Value the story receives |
|---|---|
| `UILabs.String(default, filters?)` | `string`; each filter is `(new, old) -> string` |
| `UILabs.Number(default, min?, max?, step?, dragger?, sensitivity?)` | `number` |
| `UILabs.Boolean(default)` | `boolean` |
| `UILabs.Datatype.Color3(default)` | `Color3` |
| `UILabs.Slider(default, min, max, step?)` | `number` |
| `UILabs.Choose(options, defaultIndex?)` | One of `options` (strings, numbers, tables, enums, datatypes, functions) |
| `UILabs.EnumList(namedOptions, defaultKey)` | The value under the chosen name; good for "variant name -> props table" |
| `UILabs.RGBA(color, transparency?)` | `{ Color: Color3, Transparency: number }` |
| `UILabs.Object(className?, default?, predicate?)` | An Instance picked in the Explorer, or `nil`; handle `nil` |
| `UILabs.ControlGroup({ ... })` | Groups controls under one heading; arrives as a nested table of sources |
| `UILabs.Ordered(control, order)` | The same control or group with an `Order`, its place in the panel's default sort |

The controls panel has three sort modes, set from its header: Order (the default), Name, and
Control Type. Order sorts each level, the top-level entries and the controls inside each group, by
`Order`, and an entry without one counts as 0. Ties have no fixed order, so unordered controls can
come out jumbled. Name mode also puts `Order` first when both entries have one.

In 2.4.2, `UILabs.Datatype` has only `Color3`; its `UDim2`, `UDim`, `CFrame`, `Vector2`, and
`Vector3` constructors are commented out in the source. For a size or position, use number
controls and build the value in the story, or an `EnumList` of preset values.

## Environment

`UILabs.Environment`, from the utility package. Every member has a harmless fallback outside UI
Labs, so code that uses it also runs in game.

| Member | Inside a story | Outside a story |
|---|---|---|
| `IsStory()` | `true` | `false` |
| `UserInput` | Input signals from the preview, typed as `UserInputService`, with missing members falling back to the real service | `UserInputService` |
| `InputListener` | `InputBegan`, `InputEnded`, `InputChanged`, `MouseMoved`, `GetMouseLocation` for the preview | `nil` |
| `PluginWidget` | The plugin's `DockWidgetPluginGui`; parent sounds under it to hear them in edit mode | `nil` |
| `Unmount()` | Unmounts the story | Does nothing |
| `Reload()` | Reloads the story; calling it on every mount loops forever | Does nothing |
| `CreateSnapshot(name?)` | Copies the current UI into a `ScreenGui` in `StarterGui`. This writes to the place. | Does nothing |
| `SetStoryHolder(instance?)` | Changes what "View in Explorer" selects | Does nothing |
| `GetJanitor()` | A Janitor destroyed on unmount | `nil` |
| `EnvironmentUID` / `PreviewUID` | Change on every reload / every mount | `""` |
| `OriginalG` | The real `_G`, outside the story's private one | `_G` |
| `Plugin` | The UI Labs `plugin` object | The `plugin` global, if any |

Prefer props over `IsStory()` checks inside components: a component that behaves differently in a
story is not the component the story is testing.

## Plugin features worth knowing

- Auto reload: on by default. UI Labs reloads a story when the source of any module it required
  changes, including edits made through tools. Toggle it per tab from the tab's context menu.
- Mount On Top (right-click, or Ctrl+Click): several stories, or the same one twice, at once.
  Each has its own environment.
- Mount In Widget: the story in a separate window.
- View on Viewport (`Q`): the story in the game viewport, with no zoom or offset.
- View in Explorer (`E`): selects the story's instances in the Explorer.
- Tools: measure, select elements (Shift to go deeper, Alt to block input), show outlines of
  invisible frames, mouse rulers.
- Studio Mode (options menu): queues reloads until the Studio window is focused.
- Clear Output on Reload (options menu).

## Plugin warnings

| Warning | Meaning |
|---|---|
| "Story module didn't return anything" | The module returned `nil` |
| "Story module errored when required" | An error at require time, in the story or a module it requires |
| "Story is not a valid valid story type" | The returned table has no library key UI Labs recognizes |
| "Vide story yielded when called." | The story function yielded |
| "Vide story errored when called." | The story function errored |
| "The story cleanup was not found, likely due to the story error." | Mounting failed, so there is nothing to clean up with; instances may have leaked |
| "The story cleanup errored when called. This can cause a memory leak." | Destroying the story's scope errored |
