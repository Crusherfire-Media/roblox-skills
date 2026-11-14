# Screens and devices

How to make Vide UI hold up from a small phone to a 4K monitor and a TV. Read it before laying
out a HUD, a modal, or a full-screen panel, and when UI overlaps, runs off the screen, or reads
too small on some device.

Worked out in Studio's device emulator on engine 0.741, on a game HUD with modals and full-screen
station panels. Nothing here was checked on a physical phone or TV. Numbers that belong to Roblox
(the topbar height, the touch control sizes) change between releases: read them live where this
file says so, and measure again when a layout looks off.

## Contents

- The approach
- One module owns the screen
- Scale the whole UI once
- Two kinds of pixels
- Text limits do not scale
- Lay out from the live device
- Fit panels to the screen
- Touch screens
- Stories and specs
- Checking the result
- Not covered

## The approach

1. **Author every size once, for a screen 1080 pixels tall, in offsets.** Those offsets are the
   UI's own units, called UI units below.
2. **On a larger screen, grow the whole UI with one scale.** No component does its own screen math.
3. **On a smaller screen, change the layout.** The scale stays at 1. Elements move, panels shrink
   to fit, and a panel that would shrink too far gets a compact variant.
4. **Read the screen live.** The window, the device, and the primary input can all change while
   the UI is up.

How far the UI grows, how small a panel may get, and where a HUD's pieces go are design decisions.
Show the user screenshots of the options and let them pick. The numbers and arrangements in this
file are what one game settled on, and a reasonable place to start.

## One module owns the screen

Keep the facts about the screen in one module, as Vide sources (not Charm signals: only UI reads
them). Screen-level components read it and pass layout choices down as props. Unit helpers (the
root scale, a panel's fit, a text cap) read it wherever they are used. One module means one set
of engine connections, the same answer in every ScreenGui, and one place where a story or a spec
can substitute another screen. Search the project for an existing one (look for `ViewportSize` or
`PreferredInput`) before adding it. The examples call it `Screen`.

| Fact | Read from | Changes when |
|---|---|---|
| Viewport size | `workspace.CurrentCamera.ViewportSize` | The window resizes, a phone rotates, the emulator switches device |
| Topbar inset | `GuiService:GetGuiInset()` | The device changes (`GuiService.TopbarInset` changes with it) |
| Primary input | `UserInputService.PreferredInput` | A keyboard, mouse, or gamepad is connected or used; the emulator switches device |
| Display size class | `GuiService.ViewportDisplaySize` | The device changes |

A sketch, trimmed to what the rest of this file uses:

```lua
const GuiService = game:GetService("GuiService")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

export type SimulatedScreen = {
    Size: Vector2,
    Inset: Vector2?,
    IsTouch: boolean?,
    IsLargeDisplay: boolean?,
}

const REFERENCE_SHORT_SIDE = 1080
const MINIMUM_SCALE = 1
const MAXIMUM_SCALE = 3
const LARGE_DISPLAY_BOOST = 1.25
const PHONE_SHORT_SIDE = 600
const FALLBACK_VIEWPORT = Vector2.new(1920, 1080)

local Module = {}

local realViewport = source(FALLBACK_VIEWPORT)
local realInset = source(Vector2.zero)
local prefersTouch = source(false)
local isLargeDisplay = source(false)
local isSimulating = false
local viewportConnection: RBXScriptConnection? = nil

local function refresh()
    if isSimulating then
        return
    end

    local camera = workspace.CurrentCamera
    local topLeftInset = GuiService:GetGuiInset()
    -- One batch, so a device switch reruns each binding once, with every
    -- fact already updated.
    batch(function()
        -- ViewportSize can read (1, 1) before the first frame, which would
        -- pass for a tiny phone, so the fallback stays until a real size
        -- arrives.
        if camera and camera.ViewportSize.X > 1 and camera.ViewportSize.Y > 1 then
            realViewport(camera.ViewportSize)
        end
        realInset(topLeftInset)
        prefersTouch(UserInputService.PreferredInput == Enum.PreferredInput.Touch)
        isLargeDisplay(GuiService.ViewportDisplaySize == Enum.DisplaySize.Large)
    end)
end

local function watchCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
    end
    refresh()
end

--[[
    How much the whole UI grows on this screen. Bind it to a UIScale under
    every ScreenGui the game builds.
]]
function Module.uiScale(): number
    local view = realViewport()
    local boost = if isLargeDisplay() then LARGE_DISPLAY_BOOST else 1
    return math.clamp(
        math.min(view.X, view.Y) / REFERENCE_SHORT_SIDE * boost,
        MINIMUM_SCALE,
        MAXIMUM_SCALE
    )
end

--[[
    The viewport in UI units.
]]
function Module.viewport(): Vector2
    return realViewport() / Module.uiScale()
end

--[[
    The part of the viewport below the Roblox topbar, in UI units.
]]
function Module.usableSize(): Vector2
    local view = Module.viewport()
    return Vector2.new(view.X, view.Y - realInset().Y / Module.uiScale())
end

--[[
    Whether touch is the primary input, which is when Roblox shows its touch
    controls.
]]
function Module.isTouch(): boolean
    return prefersTouch()
end

function Module.isPhone(): boolean
    local view = Module.viewport()
    return math.min(view.X, view.Y) < PHONE_SHORT_SIDE
end

--[[
    Whether a HUD should use its touch layout: the touch controls are up, or
    the screen is too small for the desktop layout.
]]
function Module.isTouchLayout(): boolean
    return prefersTouch() or Module.isPhone()
end

--[[
    Replaces the live readings with the given screen, for a story or a spec.
    Pass nil to go back to them.
]]
function Module:Simulate(screen: SimulatedScreen?)
    isSimulating = screen ~= nil
    if not screen then
        refresh()
        return
    end

    batch(function()
        realViewport(screen.Size)
        realInset(screen.Inset or Vector2.zero)
        prefersTouch(screen.IsTouch == true)
        isLargeDisplay(screen.IsLargeDisplay == true)
    end)
end

if RunService:IsRunning() then
    watchCamera()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(refresh)
    GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(refresh)
    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refresh)
else
    refresh()
end

return Module
```

- A source needs no scope, so the module creates its sources when it is required. Each getter
  reads them, which makes it a derived value: give it to a property as a binding
  (`Visible = Screen.isPhone`) or call it inside one. That is why the getters are dot functions
  with noun names, like sources, on a module that otherwise owns state. `Simulate` changes that
  state, so it is a method.
- The engine connections are made only in a running game. UI Labs and specs load a fresh copy of
  every module on each reload, and a connection would keep each copy in memory until Studio closes,
  so in edit mode the screen is read once.
- `CurrentCamera` can be replaced (some camera scripts swap it), so the viewport listener
  follows it.
- The module has no `Init` or `Start`, so it lives with the project's libraries. `Simulate` exists
  for stories and specs: propose it to the user before adding it to a module that lacks it.
- **Touch comes from `PreferredInput`, not `TouchEnabled`.** It is Roblox's own pick of the
  player's primary input, and the default controls show the thumbstick and the jump button when
  it is `Touch`, unless the game has turned them off. A laptop with a touch screen reports
  `TouchEnabled` while its player uses a mouse. A tablet with a keyboard connected reports
  `KeyboardAndMouse` while its player still taps the screen, so `isTouch()` says which controls
  Roblox shows, not whether anyone is touching the screen. Keep things a thumb can press at a
  thumb's size either way.
- **"Phone" is a size, not a platform**: a short side under about 600 UI units. Phones held
  sideways are 360 to 440 tall, and tablets start near 600. A desktop window dragged down to that
  size cannot fit a desktop HUD either, which is what `isTouchLayout` is for.
- **A TV comes from `ViewportDisplaySize`**, Roblox's own size class for the screen. Read in
  Studio's emulator:

  | Emulated device | `ViewportDisplaySize` | `IsTenFootInterface()` |
  |---|---|---|
  | Phones, handheld consoles, smaller tablets (iPad 6th generation, Galaxy Tab A9) | `Small` | false |
  | Larger tablets (iPad 10th generation, Galaxy Tab S11), laptops, monitors | `Medium` | false |
  | Xbox, PlayStation | `Large` | true |
  | Android TV | `Large` | false |

  The docs say not to use `GuiService:IsTenFootInterface()` for this: it answers by platform,
  true on any console, and the table shows it missing a TV that is not one. A 1080p monitor and a
  1080p TV have the same viewport, so listen for the class itself, as the sketch does. A refresh
  that only follows `ViewportSize` misses that switch. The class is too coarse for the rest:
  tablets land on both sides of `Small` and `Medium`, `Medium` covers a tablet and a monitor
  alike, and a scale needs a number, so everything else here works from the viewport.

## Scale the whole UI once

Put one `UIScale` directly under every ScreenGui the game builds, bound to `Screen.uiScale`:

```lua
create("ScreenGui")({
    Name = "HeadsUpDisplay",

    create("UIScale")({ Scale = Screen.uiScale }),
    statPanel({}),
})
```

The policy in the sketch is the screen's short side over 1080, never under 1 and never over 3, with
a quarter more on a TV, which is read from a couch:

| Screen | Scale |
|---|---|
| Phone, tablet, 1080p monitor | 1 |
| 1440p monitor | 1.33 |
| 4K monitor | 2 |
| 1080p TV | 1.25 |
| 4K TV | 2.5 |

- **Why one scale at the root.** UI authored for 1080p keeps the same share of every screen that
  size or taller, every authored size stays as written, and no component can forget to take part.
  Screen math inside components compounds when they nest.
- **Why not below 1.** On a phone the authored sizes take a larger share of a much smaller
  screen, and they have to: shrunk by the same ratio as the screen, text would be unreadable and
  buttons too small to press. So small screens are handled by layout.
- **A TV has less room, not more.** At 1.25 a 1080p TV is 1536 by 864 UI units, so a layout that
  fills a 1080p monitor does not fit it.
- **Leave out what Roblox places in real pixels**: `TouchGui`, `ContextActionGui`, and anything
  lined up with the Roblox topbar.
- **Do not animate this scale.** It changes when the window does. A `UIScale` change re-runs layout
  for everything under it and draws its text at new sizes.
- Once the scale exists, do screen math in UI units. `Screen.viewport` and `Screen.usableSize`
  already divide by it, so breakpoints and fits keep working at every scale.

When the game's ScreenGuis are not all built in one place, a client-only setup module (in a system,
as the `roblox-dev:game-architecture` skill places setups) can attach the scale to ScreenGuis as they appear
in `PlayerGui`, following `Screen.uiScale` from an `effect` inside a `root`. Have it scale only the
ScreenGuis the game marks, with a tag or an attribute. A watcher that scales everything it finds
also scales GUIs that Roblox, a library, or a tool adds later, and any GUI that places things in
real pixels (see "Two kinds of pixels"): at 1440p a float placed from `WorldToViewportPoint` in
a scaled ScreenGui landed a third too far across the screen. With a tag as the mark,
`CollectionService:GetTagged` is the list of scaled ScreenGuis, so the watcher keeps none of its
own.

The alternatives one game compared on screenshots were no scaling (the UI read too small at 1440p
and above) and a softer curve (the ratio to the power 0.75, so 1.24 at 1440p and 1.68 at 4K). The
choice is the user's.

## Two kinds of pixels

Under a `UIScale`, some numbers are in UI units and some are in real pixels. "Real pixels" here
means screen offset units, the ones `ViewportSize` and `AbsoluteSize` report. On a high-density
display they are not physical pixels. Mixing the two kinds is the bug that only shows on large
screens, where the scale is no longer 1.

| UI units (before the scale) | Real pixels (after the scale) |
|---|---|
| Offsets in `Size` and `Position` | `AbsoluteSize`, `AbsolutePosition`, `TextBounds` |
| A fixed `TextSize` | `Camera.ViewportSize`, `GuiService:GetGuiInset()`, `GuiService.TopbarInset` |
| `Screen.viewport()`, `Screen.usableSize()` | Mouse and touch positions |
| | `UITextSizeConstraint` limits (next section) |

- Read the screen through the screen module, never straight from the camera.
- A value measured from `AbsoluteSize` or `AbsolutePosition` and written back into an offset is
  divided by the scale in effect there: `Screen.uiScale()` times any `UIScale` on the frames in
  between. Without that, a point lands 33 percent too far out at 1440p and twice as far at 4K.
- Better, measure less. Anchors, `AutomaticSize`, and list layouts place things without reading
  anything back, and reading `AbsoluteSize` forces layout to run (see the `roblox-dev:roblox-performance`
  skill).
- `AbsolutePosition` and the `Position` of a mouse or touch `InputObject` both start below the
  Roblox topbar, even in a ScreenGui that ignores the topbar inset, where a frame at the very top
  of the screen reports a negative Y. `UserInputService:GetMouseLocation()` and `ViewportSize`
  include the topbar. Subtract `GuiService:GetGuiInset()` to move such a point into the space
  `AbsolutePosition` uses.
- `ViewportSize` is the device's safe area: it leaves out a notch or a camera cutout.
  `ScreenGui.ScreenInsets` decides which area a ScreenGui fills. `IgnoreGuiInset = true` is the
  older way to set it to `DeviceSafeInsets`, and it is not saved with the instance.

## Text limits do not scale

Height of the drawn text, in real pixels, for a label under a `UIScale` (measured):

| Label | Scale 0.5 | Scale 1 | Scale 2 |
|---|---|---|---|
| `TextSize = 20` | 10 | 20 | 40 |
| `TextSize = 60` | | 60 | 120 |
| `TextScaled`, no constraint, in a box 40 tall | 20 | 40 | 80 |
| `TextScaled` with `MaxTextSize = 20` | 20 | 20 | 20 |
| `TextScaled` with `MinTextSize = 14`, box too small | 14 | 14 | 14 |
| `TextScaled` in a box 400 real pixels tall, any `MaxTextSize` | | 100 | 100 |

A fixed `TextSize` follows the scale and needs nothing, which is one more reason to prefer it (the
`roblox-dev:roblox-performance` skill has the others). `TextScaled` text follows its box, but the limits on a
`UITextSizeConstraint` are real pixels, so:

- **A cap stops text from growing with the root scale.** On a 4K screen the boxes double and the
  capped text stays the size it was. Multiply each cap by the root scale. Only the root scale: a
  panel's fit scale only shrinks, and a cap only limits growth.

  ```lua
  create("UITextSizeConstraint")({
      MaxTextSize = function()
          return TITLE_MAX_TEXT_SIZE * Screen.uiScale()
      end,
  })
  ```

- **`TextScaled` text never draws above 100 real pixels**, whatever its constraint says. A title
  that should reach 60 at 1080p stops short of the 120 it wants at 4K. A fixed `TextSize` is the
  way past that.
- **A minimum stops text from shrinking with its box.** A panel scaled to half size keeps its 14
  pixel text in boxes half as tall, and the text spills out. This is what limits how far a panel
  can shrink (see "Fit panels to the screen").
- **Move or fade things in; do not grow them from nothing.** A button that scales up from zero
  squeezes its caption through every size on the way, and text with a minimum cannot follow.
  Sliding it at full size has no such frames.

## Lay out from the live device

A layout chosen from a value read once is wrong in two ordinary cases. The device changes during a
session: a tablet player connects a keyboard, a console player switches to a connected keyboard
and mouse, the emulator switches device. And the screen is not settled when startup code runs, so
a size read in `Init` or at require time can be a default, not the player's screen.

So the screen-level component binds placement to the screen module:

```lua
const DESKTOP_ANCHOR = Vector2.new(0, 1)
const DESKTOP_POSITION = UDim2.new(0, 24, 1, -24)
const TOUCH_ANCHOR = Vector2.zero
const TOUCH_POSITION = UDim2.fromOffset(12, 12)

local function headsUpDisplay()
    return create("ScreenGui")({
        Name = "HeadsUpDisplay",

        create("UIScale")({ Scale = Screen.uiScale }),

        create("Frame")({
            Name = "StatDock",
            BackgroundTransparency = 1,
            AnchorPoint = function()
                return if Screen.isTouchLayout() then TOUCH_ANCHOR else DESKTOP_ANCHOR
            end,
            Position = function()
                return if Screen.isTouchLayout() then TOUCH_POSITION else DESKTOP_POSITION
            end,

            statPanel({}),
        }),
    })
end
```

When the two layouts are different trees, not the same tree in different places, swap them:

```lua
show(Screen.isTouchLayout, function()
    return hotbarRow({})
end, function()
    return hotbarColumn({})
end)
```

Code that is not built with Vide reads the screen at the moment it acts (when a panel opens), not
once at startup.

**Reusable components take the variant as a prop.** A component that picks its own layout from
the screen module can only be seen in a story on whatever screen Studio has. Give it a prop, and
let the screen-level component that mounts it pass `Screen.isPhone`. Keep each variant's numbers
in one table, so the two layouts are read side by side and never as `if` branches scattered
through the tree. With more than two variants, make the prop a string enum
(`Layout: "Regular" | "Compact" | "Tablet"`).

```lua
type Metrics = {
    Size: Vector2,
    TitleTextSize: number,
}

type GiftPanelProps = {
    IsCompact: (boolean | () -> boolean)?,
}

const REGULAR: Metrics = table.freeze({ Size = Vector2.new(420, 610), TitleTextSize = 32 })
const COMPACT: Metrics = table.freeze({ Size = Vector2.new(632, 340), TitleTextSize = 24 })

local function giftPanel(props: GiftPanelProps)
    -- Derived, so the bindings rerun when the variant flips and not on
    -- every pixel of a window resize.
    local metrics = derive(function(): Metrics
        return if read(props.IsCompact) then COMPACT else REGULAR
    end)

    return create("Frame")({
        Size = function()
            local size = metrics().Size
            return UDim2.fromOffset(size.X, size.Y)
        end,

        create("TextLabel")({
            TextSize = function()
                return metrics().TitleTextSize
            end,
        }),
    })
end
```

## Fit panels to the screen

A modal has a design size: the size it is authored at, taken from its metrics, not read back from
`AbsoluteSize`. Scale it down to fit the room it has, never up past 1 and never below a floor:

```lua
type FitOptions = {
    -- Width of docked chrome the panel must not cover, in UI units.
    ReservedWidth: (() -> number)?,
}

const EDGE_PADDING = 16
const MINIMUM_FIT_SCALE = 0.5

local function fitScale(designSize: () -> Vector2, options: FitOptions?): () -> number
    local reservedWidth = if options then options.ReservedWidth else nil

    return function(): number
        local design = designSize()
        local usable = Screen.usableSize()
        local reserved = if reservedWidth then reservedWidth() else 0
        local fit = math.min(
            (usable.X - EDGE_PADDING * 2 - reserved) / design.X,
            (usable.Y - EDGE_PADDING * 2) / design.Y
        )
        return math.clamp(fit, MINIMUM_FIT_SCALE, 1)
    end
end
```

The screen-level component wires it up: a dock of the design size, centered, holding the `UIScale`
and the panel. `UIScale` scales about the dock's `AnchorPoint`, so a centered dock stays centered.
`REGULAR` and `COMPACT` are the panel's metrics from the example above; a panel in its own module
exports them.

```lua
const CENTER = Vector2.new(0.5, 0.5)
const SCREEN_CENTER = UDim2.fromScale(0.5, 0.5)

local function giftModal()
    local function designSize(): Vector2
        return if Screen.isPhone() then COMPACT.Size else REGULAR.Size
    end

    return create("Frame")({
        Name = "GiftDock",
        BackgroundTransparency = 1,
        AnchorPoint = CENTER,
        Position = SCREEN_CENTER,
        Size = function()
            local size = designSize()
            return UDim2.fromOffset(size.X, size.Y)
        end,

        create("UIScale")({ Scale = fitScale(designSize) }),
        giftPanel({ IsCompact = Screen.isPhone }),
    })
end
```

- **The floor.** Past about half size, text with a minimum no longer fits its boxes, so shrinking
  further trades a panel that runs off the screen for one nobody can read. On a 667 by 375 phone,
  a floor of 0.75 left panels cut off and 0.5 fit them. The clamp also keeps the scale above zero
  when a window is dragged very small.
- **When to write a compact variant.** A fit near the floor is the sign: at 0.6, text authored at
  18 draws at 11 and a 44 pixel button at 26. Give the panel a compact variant with the same
  content rearranged for a wide, short screen (side by side instead of stacked, less decoration)
  so its text and buttons are back at a readable size.
- **Switch variants on `Screen.isPhone`, never on the fit.** The fit depends on the variant's
  size, so each would change the other.
- **A fit scale is fractional**, so the panel's text lands on pixel sizes nothing else on screen
  uses, which the `roblox-dev:roblox-performance` skill's text rules count against. A compact variant sized
  to fit at 1 avoids it.
- **Reserve room for chrome that stays up.** `ReservedWidth` is the width of a docked column the
  panel must not cover. Move the dock's center by half of it, so the panel centers in what is
  left.
- In a ScreenGui that ignores the topbar inset, a `Position` of 0.5 centers on the whole screen,
  half a topbar too high. Add half the inset, in UI units, to center in the usable part.
- **Do not put an entrance animation on this `UIScale`.** Every frame of it re-runs layout and
  draws the panel's text at a new size. Fade the panel in or slide it.

## Touch screens

Roblox draws its own controls over the game when the primary input is touch, in real pixels, in
`PlayerGui.TouchGui`:

- **The thumbstick** appears where the left thumb lands, anywhere in a region much larger than the
  stick: with the default movement mode, `DynamicThumbstickFrame` covers the left 40 percent and
  the lower two thirds of a screen held sideways.
- **The jump button** (`JumpButton`) sits in the lower right. One layout of the default
  `PlayerModule`, measured from the screen's right and bottom edges:

  | Short side of the touch area | Button size | Left edge | Top edge |
  |---|---|---|---|
  | 500 or less | 70 | 95 from the right | 90 from the bottom |
  | Over 500 | 120 | 170 from the right | 210 from the bottom |

  The default scripts have a second layout with different numbers, so use the table to plan. Where
  a layout has to clear the button exactly, read its `AbsolutePosition` and `AbsoluteSize` live.

What to do about them:

- **Reflow when a stack would reach a control.** On a phone too short for three rows above the
  jump button, a two-wide, three-tall grid of buttons becomes three wide and two tall. Compute
  that from the usable height and the button's top edge, not from a list of device names.
- **Hide them while a full-screen panel takes presses where they are:**

  ```lua
  root(function()
      effect(function()
          GuiService.TouchControlsEnabled = not isAnyFullScreenPanelOpen()
      end)
  end)
  ```

  This hides the thumbstick and the jump button and stops touch movement. It is a touch-only
  switch, so keyboard and gamepad movement are separate. Run it once from client startup code,
  in a root that lives for the session, not from a component: one place owns the property and no
  story reaches it. The player can no longer walk away, so the panel needs its own close button,
  on screen at every size.
- **Keep drag surfaces out of the thumbstick's region.** A press there that no button takes starts
  the stick. Whether a button inside the region always wins the press was not checked here, so
  test anything pressed often that has to sit there.
- **Make anything pressed with a thumb about 44 pixels or more.**
- **The free part of the topbar strip is `GuiService.TopbarInset`**: a `Rect`, in real pixels,
  that changes as Roblox's own buttons do. Keep it in a source to place a compact row there. The
  docs also offer a ScreenGui with `ScreenInsets` set to `TopbarSafeInsets`, which fills that
  area; it was not tried here.

One arrangement that worked on phones held sideways, as an option to show the user:

- Status in the top left, action buttons in the top right at 60 pixels, a hotbar along the bottom
  between the two controls, and a compact row in the free part of the topbar strip. A column of
  buttons down either side did not fit, because both controls cut it short.
- Secondary buttons tucked behind a more button that keeps one fixed cell, so a second press lands
  on the same spot. While they are tucked, their notice badges show on the more button.
- A modal takes the whole usable area and the HUD buttons hide while it is open. A tablet has room
  to keep them, so there the modal reserves their width instead.

## Stories and specs

- **Give each layout variant a control.** A boolean control passed to `IsCompact` shows both
  layouts in one story, on any Studio viewport. It belongs in a group named for what it changes,
  such as `Layout` (the `roblox-dev:vide-ui-labs` skill covers grouping and ordering).
- **UI Labs has no device preview, and `Screen:Simulate` alone is not one.** A story has no root
  scale, and its preview frame is not the simulated size. To see a component on a small screen,
  pin the screen while the story builds, and build the story inside a frame sized to
  `Screen.usableSize()` in offsets that holds a `UIScale` bound to `Screen.uiScale`. That frame
  comes out at the simulated screen's size below the topbar. Choose the screen from a list
  control in the `Preview` group, and key the story by it
  (`indexes(function() return { [controls.Screen()] = true } end, build)`) so a new choice
  rebuilds on the new screen. Each mounted story has its own copy
  of every module, so the pin does not leak. A screen larger than the preview cannot be shown this
  way. The frame's size was checked; no shared story helper has been built on it yet.
- "View on Viewport" shows a story at Studio's own viewport size, without the root scale the game
  adds. UI Labs's zoom uses a `UIScale`, so it shows the text limit behavior described above, not
  a real small screen.
- **A spec that mounts UI pins the screen first**, in `beforeEach` or in the test's own setup, and
  again after `jest.resetModules()`. Otherwise it reads whichever device Studio's emulator is set
  to, and passes or fails with it. Each spec file loads its own copy of the module, so nothing
  needs putting back.
- How a layout looks stays out of specs, as the `roblox-dev:roblox-testing` skill says. If the user wants the
  scale policy or the fit calculation pinned, plan it through that skill: agree the behaviors
  first, and assert the rule (never below 1, never above the cap), not the tuning numbers.

## Checking the result

Check a fixed set of screens after a change to how the UI scales or where a HUD's pieces go, since
each one catches something different. After a change to one panel, the smallest phone and the
largest monitor are the two that matter most.

| Screen | Catches |
|---|---|
| Small phone (667 by 375) | Panels that do not fit, HUD crowding |
| Short phone (about 360 tall) | Stacks that reach the jump button |
| Large phone | Layouts that only worked at one phone size |
| Tablet | Touch layout with room to spare, reserved widths |
| 1080p | The authored layout |
| 1440p and 4K | Mixed units, capped text that did not grow |
| Console, Android TV | Gamepad as the primary input, and the TV scale |

- Switch Studio's Device Emulator to each screen and capture a screenshot of each. A custom
  device in the emulator gives sizes that have no preset, such as 1440p and 4K.
- **The emulator is a Studio setting that every agent on that window shares**, and switching it
  changes a running playtest's screen too. Check that no one else has a playtest running there
  first, and stop the simulation when done.
- Start the playtest on the device. Then switch devices during it: a layout that follows the live
  screen reflows, and one that read the screen once shows as a mix of two layouts.
- Measure as well as look. Compare the `AbsolutePosition` and `AbsoluteSize` of HUD pieces with the
  touch controls and the screen edges, and record the smallest text heights (`TextBounds.Y`) per
  screen, so two options can be compared by number.
- Then show the user screenshots. Whether it looks right is their call.

## Not covered

- Gamepad selection and navigation on a TV.
- Phones held upright.
- The player's Text Size setting (`GuiService.PreferredTextSize`). Per the docs, `TextScaled`
  text and text limited by a `UITextSizeConstraint` do not follow it, and `AutomaticSize` boxes
  grow with it. No layout here was checked at a larger setting.
- Thumb reach on tablets, where the top corners are a long way from where the hands hold.
- BillboardGuis and SurfaceGuis, which have no screen to scale to.
- Physical devices.
