---
name: vide-ui-labs
description: UI Labs, the Roblox Studio storybook plugin, used with Vide - .story and .storybook modules, controls, the UI Labs utility package, and keeping UI code safe to run in edit mode. Load it together with the roblox-dev:vide skill whenever you create or change a Vide component or screen (every piece of UI gets a story in the same change); when writing or fixing a story, storybook, or controls, including grouping and ordering a story's controls panel; when a story errors, does not reload, or does not show up in UI Labs; and when UI code must run safely outside a playtest.
---

# UI Labs with Vide

UI Labs is a Studio plugin that renders **stories** in edit mode, with no playtest, and reloads
them whenever the code they use changes. A story is a ModuleScript whose name ends in `.story`.
Every Vide component and screen gets a story, written in the same change as the UI: it is where
the user sees the UI, compares design ideas, and checks edge cases.

This skill targets UI Labs plugin 1.6 and utility package 2.4. The `roblox-dev:vide` skill's rules apply to
story code too; load it as well. The full list of controls and `Environment` utilities is in
[references/api.md](references/api.md). The script in
[references/story-check.md](references/story-check.md) mounts stories the way UI Labs does and
reports errors, yields, and edit-mode leaks.

## What UI Labs does with your code

When a story mounts, UI Labs loads the story and every module it requires, fresh from source, with
its own `require`, `script`, and `_G`. It does this again on every reload. So:

- **The code runs in the real edit DataModel.** UI Labs's "sandbox" means fresh copies of modules
  and a private `_G`, not a copy of the place. Anything a story or a required module parents into
  the DataModel outside the story's frame (a `BlurEffect` in `Lighting`, a part in `workspace`, a
  `ScreenGui` in `StarterGui`) is a real edit that gets saved with the place, and it is created
  again on every reload.
- **Top-level code of every required module runs on every reload**, with plugin permissions.
  Connections made there are never disconnected, so each reload adds another.
- **The game is not running.** `RunService:IsRunning()` is false, `Players.LocalPlayer` is nil,
  the module loader never runs (no `Init` or `Start`), and no server answers remotes.
- **Each mounted story has its own copy of every module**, including Vide and any Charm stores.
  Two stories never share state.
- **String requires support `./`, `../`, `@self`, and `@game`.** Other aliases fail to resolve.
- **Input and sound are limited.** `UserInputService` gets no input inside the plugin window, and
  sounds play in edit mode only when parented inside the plugin's widget. The utility package's
  `Environment.UserInput` and `Environment.PluginWidget` cover both (see the reference).

## Keep UI safe to run in edit mode

- **Components get their data through props.** A component that a story renders never requires
  game services, state stores, or remotes, and never reads `Players.LocalPlayer`. Split a screen
  into a view component (props in, instances out, with a story) and a thin wrapper that connects
  it to game state and passes sources down (no story). A screen module written the way the `roblox-dev:vide`
  skill's `references/screens.md` describes is safe to require (it connects to nothing in edit
  mode, and a story can pin it). Layout variants still arrive as props.
- **A story only touches its own frame.** Effects outside the UI (blur in `Lighting`, camera
  moves, sounds in `SoundService`, parts in `workspace`) sit behind a prop the story leaves off,
  or behind `RunService:IsRunning()`. When a component does create one, it registers
  `cleanup(instance)` so the instance goes away with the story.
- **Module top-level code stays passive.** Creating instances in the DataModel, connecting to
  signals, and yielding all belong in functions, or behind `RunService:IsRunning()` when they must
  run at require time.

## Where stories live

- Keep stories in one Studio-only folder that the game never loads or replicates, for example
  `ServerScriptService.Stories`: outside the game's module folders, with no loader tag and no
  relocation attributes. Follow the project's architecture rules for the exact location.
- Put one storybook module at its root, and mirror the component folders in subfolders; UI Labs
  shows each subfolder as a folder.

  ```lua
  -- ServerScriptService.Stories["GameUI.storybook"]
  return {
      name = "Game UI",
      storyRoots = { game:GetService("ServerScriptService").Stories },
  }
  ```

- Name each story after its component: `ShopPanel.story` for `ShopPanel`. Stories require
  components and data with absolute `@game/...` paths.

## Writing a Vide story

A story module returns a table. Its keys (`vide`, `controls`, `story`, `summary`) and the `props`
keys the story receives (`controls`, `target`) are UI Labs API names and stay lowercase. The
control names inside `controls` are yours and follow the project's key style.

```lua
const Vide = require(...) -- the Vide module the components require, so they share the story's scope
const UILabs = require(...) -- the UI Labs utility package
const ShopItemCard = require("@game/ServerScriptService/Modules/Components/ShopItemCard")

const CONTROLS = {
    Item = UILabs.Ordered(UILabs.ControlGroup({
        Name = UILabs.Ordered("Golden Spatula", 1),
        Rarity = UILabs.Ordered(UILabs.Choose({ "Common", "Rare", "Legendary" }), 2),
        Price = UILabs.Ordered(UILabs.Slider(250, 0, 10000, 50), 3),
    }), 1),
    Player = UILabs.Ordered(UILabs.ControlGroup({
        IsOwned = UILabs.Ordered(false, 1),
        -- Below Price, the card shows as unaffordable.
        Cash = UILabs.Ordered(UILabs.Slider(1000, 0, 10000, 50), 2),
    }), 2),
}

type StoryProps = {
    controls: {
        Item: {
            Name: () -> string,
            Rarity: () -> string,
            Price: () -> number,
        },
        Player: {
            IsOwned: () -> boolean,
            Cash: () -> number,
        },
    },
    target: Frame,
}

local function story(props: StoryProps)
    local item = props.controls.Item
    local player = props.controls.Player

    return ShopItemCard({
        Name = item.Name,
        Rarity = item.Rarity,
        Price = item.Price,
        IsOwned = player.IsOwned,
        CanAfford = function()
            return player.Cash() >= item.Price()
        end,
        Purchased = function()
            print("Purchased")
        end,
    })
end

return {
    summary = "A shop item card in every rarity and ownership state.",
    vide = Vide,
    controls = CONTROLS,
    story = story,
}
```

- `story` runs **once**, inside a stable Vide scope that UI Labs destroys on unmount and before
  every reload. Return the root instance and UI Labs parents it into the preview frame, or parent
  it to `props.target` yourself and return nothing.
- Every control reaches the story as a **Vide source** in `props.controls`. Pass it straight to a
  prop typed `T | () -> T`, and the preview follows the control live. A component that reads a
  prop once shows only the first value; make that prop accept a source.
- Callbacks the game would handle (purchases, closing) do something visible in the story: print,
  or update a story-local `source` so the UI reacts the way it would in game.
- To reset story state when a control changes (refill a tray, restart a timer), key that part of
  the story by the control, so a new value rebuilds it with fresh state:

  ```lua
  return indexes(function()
      return { [controls.RestockCount()] = true }
  end, function(_, restockCount: number)
      local soldCounts = source({})
      -- ...build the panel from restockCount and soldCounts
  end)
  ```

  Setting a source from an effect to reset it is the pattern the `roblox-dev:vide` skill steers away from.
- The story function never yields; UI Labs warns "Vide story yielded when called." when it does.

## Organize the controls

The controls panel lists entries by their `Order` unless the user picks another sort, and an
entry without one counts as 0. Unordered controls all tie, so they come out in no reliable order
and can shuffle between reloads. That is what makes a story's panel look disorganized, so group and
order the controls of every story:

- **Group by what the controls change**, named in the component's own terms: `Item`, `Player`,
  `Layout`, `Look`, `Motion`, `Hatching`. Two to six controls make a readable group. A story with
  three controls or fewer can list them ungrouped, still ordered.
- **Put story-only settings last, in a group named `Preview`**: the backdrop, muting sounds,
  fitting to the preview, a pretend server's delay or refusal. They are not the component's props,
  so they should not sit among them.
- **Order every group and every control** with `UILabs.Ordered(control, n)`, numbering from 1 at
  each level: groups among the top-level entries, controls within their group. Put what a reader
  reaches for first at the top, usually content, then state, then looks.
- **Read groups as nested tables.** A group reaches the story as a table of sources, so
  `props.controls.Layout.Width` is a source. Type `controls` with the same nesting; then a control
  moved to another group shows up as a type error wherever a read missed the move.
- **Comment a control** when its effect isn't clear from its name: its unit, what 0 means, or that
  changing it starts the story over.
- **Kits share groups.** When several stories share a story kit, the kit defines the shared groups,
  and a story adds its own by cloning the kit's table and adding a key. A kit that reads many
  controls by name can open the groups into one flat table once, at the story's entry, as long as
  control names stay unique across groups.

## What a story covers

- One story per component or screen, with a control for every prop that changes how it looks,
  grouped and ordered as above.
- Controls for the edge cases: empty lists, one item and many, long names, zero and very large
  numbers, locked and owned states, and each disabled action with its reason showing.
- Sample data that looks like the game's: real catalog entries or realistic values. Build it in
  the story, not in the component, and pick catalog entries by a rule (cheapest, priciest, first
  few) instead of hard-coded names, so a renamed entry cannot silently empty the story.
- Design ideas side by side: a `Choose` or `EnumList` control that switches between variants, or
  the same story mounted twice ("Mount On Top") with auto reload turned off on one copy.
- Screen sizes: a control for each layout variant the component has. "View on Viewport" (`Q`)
  shows the story in the game viewport, at Studio's viewport size. The zoom tool scales with
  `UIScale`, which can distort some layouts. The `roblox-dev:vide` skill's `references/screens.md` covers
  layout across devices and what a story can show of it.

## Steps

1. Write or change the component by the `roblox-dev:vide` skill.
2. In the same change, write or update its story so every prop that changes the look has a
   control, grouped and ordered (see "Organize the controls").
3. Run the story check in [references/story-check.md](references/story-check.md) on the new or
   changed stories (a story, or the folder holding them), by running its Luau in the edit
   session. It mounts each story the way UI Labs does and reports errors, yields, and anything
   left in the DataModel. Fix what it reports, then run it again.
4. Measure each changed story's layout by "Measuring the result" in the `roblox-dev:vide`
   skill's `references/layout-quality.md`: cut or overlapping text, corners, clipped outlines,
   scroll bar room, gaps. Set controls to the long-text and many-items cases too (the story
   check's last note shows how). Fix what it finds.
5. Tell the user which story to open in UI Labs and what to check on screen, including any
   warning you left and why. Whether it looks right is their call.

Done when every new or changed component has a story that mounts with no errors, yields, or
DataModel additions, its layout measurement shows no defect that you have not explained to the
user, and its grouped, ordered controls drive the component live.

## Common problems

When a story errors, does not show up, does not reload, leaves something in the place, or its
controls do not drive the preview or come out jumbled, find the message or symptom in
[references/common-problems.md](references/common-problems.md).
