# Roblox platform facts for UI design

What the engine and platform decide for you, and the numbers they don't give. This file is about
design consequences. The code that reads these values live (one screen module, one root
`UIScale`, the touch control layout) is in the `roblox-dev:vide` skill's `references/screens.md`; what UI
costs is in `roblox-dev:roblox-performance`'s `references/ui.md`. Many docs pages render fully only as their
`.md` variants or in the `Roblox/creator-docs` GitHub source, which is why links point there.

## Contents

- Safe areas and the top bar
- Core UI the game shares the screen with
- Screen classes and scaling
- Text and fonts
- Input
- Player accessibility settings
- World-space UI
- VR
- Console
- Content rules for UI text and images
- Costs that change a design

## Safe areas and the top bar

- `ScreenGui.ScreenInsets` defaults to **`CoreUISafeInsets`**, which avoids device cutouts and
  Roblox's core UI. Use it for any ScreenGui with buttons or important status [standard]
  ([ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui.md)).
  `DeviceSafeInsets` avoids notches but not core UI; `None` is for backgrounds and other
  non-interactive art; `TopbarSafeInsets` fills the free strip inside the top bar, whose rectangle
  is `GuiService.TopbarInset` [standard].
- `IgnoreGuiInset` is **not deprecated**. It's a legacy toggle that switches `CoreUISafeInsets`
  to `DeviceSafeInsets` [standard].
- ScreenGuis in different inset modes have different origins, so HUD pieces that must line up
  share one mode [practitioner; inference].
- The top bar's reserved height **grew from 36 to 58 px in 2023 and "may vary based on device and
  screen size"** [standard] ([Experience Controls beta](https://devforum.roblox.com/t/studio-beta-for-experience-controls-available-now/2567355)).
  Community measurements say 44 or 48 [practitioner]. Read `TopbarInset` and its changed signal;
  never hardcode a height.
- The controls moved from the right to the left in November 2023 [standard]. One source puts the
  expanded menu on the right, so check placement in Studio before you describe it.
- **`TopbarSafeInsets` has open bugs**: since 2 December 2025, on Xbox and other consoles it sizes
  with zero height (reproducible in Studio's Xbox One emulator), and a regression stopped it
  covering the space right of the menu buttons [practitioner]
  ([console report](https://devforum.roblox.com/t/screenguiscreeninsets-topbarsafeinsets-is-incorrect-on-consoles/4111410)).
  Top-bar UI reads `TopbarInset` directly and gets checked in the Xbox emulator [inference].

## Core UI the game shares the screen with

- The 9-dot Roblox menu holds Text Chat, Leaderboard, Emotes, and Backpack. **The new experience
  controls can't be disabled** through `CoreGuiType` [standard].
- `StarterGui:SetCoreGuiEnabled` takes PlayerList, Health, Backpack, Chat, All, EmotesMenu,
  SelfView, Captures, and AvatarSwitcher [standard]
  ([CoreGuiType](https://create.roblox.com/docs/reference/engine/enums/CoreGuiType.md)). Hide the
  ones the game replaces (a custom hotbar replaces Backpack) so players don't see two.
- `SetCore("TopbarEnabled", false)` hides the top bar and also chat and the player list; it isn't
  deprecated [standard]. `SetCore("SendNotification")` shows a core notification bottom-right with
  up to two buttons [standard]. `SetCore` can fail before core scripts load, so it's called in a
  `pcall` with retries [standard].
- Only a ScreenGui that is a direct child of StarterGui with `ResetOnSpawn = false` survives a
  respawn; one inside a Folder still resets [standard]
  ([On-screen containers](https://create.roblox.com/docs/ui/on-screen-containers.md)). Menus that
  must keep their state across death (settings, an open inventory) need this [inference].
- On touch, Roblox draws the thumbstick and jump button in `PlayerGui.TouchGui`;
  `GuiService.TouchControlsEnabled = false` hides them [standard]. Nothing documents whether
  `CoreUISafeInsets` avoids them, so assume it doesn't [inference]. `roblox-dev:vide`'s `references/screens.md` has the
  measured positions.
- No official 2026 map of core UI placement per platform exists (thumbstick, jump, hotbar, player
  list, console layout).

## Screen classes and scaling

- Roblox's cross-platform guide: position with **Scale plus AnchorPoint**; don't size with a fixed
  percentage ("a fixed 75% width would be far too large on 4K TVs"); adapt by
  **`GuiService.ViewportDisplaySize`**: `Small` (most phones, tablets, handhelds), `Medium` (most
  laptops and monitors), `Large` (most TVs) [standard]
  ([Cross-platform](https://create.roblox.com/docs/projects/cross-platform.md)).
- **`IsTenFootInterface()` is deprecated**; the docs say to use `ViewportDisplaySize` instead
  [standard].
- The pattern the `roblox-dev:vide` skill uses, offsets authored for a 1080-tall screen and one
  root `UIScale`, is community practice, not Roblox guidance [practitioner]; its
  `references/screens.md` has it.
  `UIScale` other than 1 breaks `AutomaticSize` [practitioner, staff reply].
- UI Styling (StyleSheet, StyleRule, tokens, `@ViewportDisplaySizeSmall`, `@PreferredInputTouch`
  queries) has been in Client Beta since 20 January 2026; no full release was found, so shipping
  on it carries beta risk [standard].
- Upgraded `UIGradient` types (Radial, Elliptical, Conical) and `Scale`/`TileMode` are beta.
  `UIStroke` supports `StrokeSizingMode` ScaledSize and several strokes per object; don't tween
  stroke `Thickness` on text, it flickers [standard]
  ([Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers.md)).

## Text and fonts

- **`TextScaled` sizes each label to its own box**, so labels with different strings end up
  different sizes, and it ignores the player's text size setting [practitioner; standard]. Use one
  `TextSize` per text role (title, body, caption) instead.
- **`GuiService.PreferredTextSize`** (Medium, Large, Larger, Largest) went live for everyone on
  25 August 2025 [standard] ([announcement](https://devforum.roblox.com/t/3136967)). It grows text
  at render time; `AutomaticSize` elements grow with it, wrapped text wraps more, and
  `TextService:GetTextBoundsAsync` accounts for it. Only `TextScaled` or a `UITextSizeConstraint`
  opts a label out, and staff chose accessibility over layout stability when developers objected
  [standard]. Design every text container to survive Largest.
- `UITextSizeConstraint.MinTextSize` shouldn't go below 9 [standard].
- **Builder Sans** is the platform font (with Builder Extended and Builder Mono, March 2024).
  Gotham and Arial were removed on 28 May 2024 and replaced with Montserrat and Arimo [standard]
  ([Builder font](https://devforum.roblox.com/t/2868222)).
- Text inside images isn't translated, narrated, or re-contrasted. Keep words in TextLabels
  [standard].

## Input

- **`GuiButton.Activated`** fires on mouse release, touch release, and gamepad A or Cross while
  navigating UI; `MouseButton1Click` is mouse-only. `SecondaryActivated` covers right-click,
  long-press, and R3 [standard]
  ([GuiButton](https://create.roblox.com/docs/reference/engine/classes/GuiButton.md)).
- **`UserInputService.PreferredInput`** (KeyboardAndMouse, Gamepad, Touch; full release 14
  October 2025) is the signal for choosing a UI layout. `TouchEnabled` is now true on touch
  laptops and handhelds, so it no longer means a phone [standard]
  ([PreferredInput](https://devforum.roblox.com/t/full-release-introducing-preferredinput-and-improved-touch-capabilities/3750890)).
  It changes at runtime, so layouts re-evaluate when it does [inference].
- Gamepad focus: `Selectable`, `NextSelectionUp/Down/Left/Right`, `SelectionImageObject`,
  `SelectionOrder` (initial pick only), and `SelectionGroup` with `SelectionBehavior` `Stop` (keep
  focus inside, for modals) or `Escape` (let it leave, for HUD clusters). `GuiService:Select(parent)`
  and `GuiService.SelectedObject` set focus; `SelectedObject` resets to nil when the object goes
  off screen. `GuiService.AutoSelectGuiEnabled` and `GuiNavigationEnabled` switch the engine's own
  selection behavior [standard]
  ([GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject.md)). Set focus
  yourself when a screen opens instead of relying on auto-select [inference].
- Whether a `ContextActionService` binding on `ButtonB` runs before Roblox's own B (which leaves UI
  navigation) wasn't found in the docs [unverified]. Check a Back-to-close design in the
  Controller Emulator.
- The virtual cursor (`GamepadService:EnableGamepadCursor`) needs `StarterGui.VirtualCursorMode =
  Enabled`, and **in VR it is always on** whatever that property says [standard]. Prefer focus
  navigation on gamepad; keep the cursor for free-form surfaces such as a map [inference].
- Button glyphs come from `UserInputService:GetImageForKeyCode` (Xbox and PlayStation variants)
  and `GetStringForKeyCode`, or the beta `InputActionLabel`; never hardcode one console's art
  [standard] ([Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines.md)).
- The Input Action System (InputContext, InputAction, InputBinding with `UIButton` for touch) is
  in Client Beta; a 24 February 2026 change binds each binding to one input source [standard].
  `ContextActionService` touch buttons are capped at 7 [standard].

## Player accessibility settings

Roblox exposes three settings, and its docs say UI "should accommodate each" [standard]
([Accessibility](https://create.roblox.com/docs/production/publishing/accessibility.md)):

| Setting | What to do |
|---|---|
| `GuiService.PreferredTextSize` | Leave text unscaled by `TextScaled`; let containers grow |
| `GuiService.PreferredTransparency` | Multiply each `BackgroundTransparency` by it (1 default, 0 fully opaque) and update on change |
| `GuiService.ReducedMotionEnabled` | Set tween time to 0 or fade instead of moving |

There is no player setting for overall UI scale. Settings that duplicate these three belong to
Roblox, not the game [inference].

## World-space UI

- `BillboardGui` faces the camera; Scale sizes are in studs and shrink with distance, Offset stays
  constant in pixels; `MaxDistance` defaults to infinite. `SurfaceGui` sits on a face, is
  occluded, and defaults `MaxDistance` to 1000 [standard]
  ([In-experience containers](https://create.roblox.com/docs/ui/in-experience-containers.md)).
  Give every one a finite `MaxDistance` so far labels don't clutter the screen.
- Buttons in either take input only when the gui is parented to PlayerGui (with `Adornee` set),
  and a SurfaceGui also needs its part's `CanQuery = true` [standard].
- World-space cues are the best tutorial tool for most games: an icon over the thing to use beat
  text in Roblox's own funnel example (`onboarding-and-progression.md`) [practitioner].

## VR

- ScreenGuis render on a Roblox panel that "follows the headset", with a laser pointer and a VR
  bottom bar holding chat, inventory, leaderboard, and emotes (since September 2022) [standard]
  ([VR UI update](https://devforum.roblox.com/t/roblox-vr-ui-update/1998969)).
- **Roblox publishes no panel distance, size, curvature, or VR text size**, and the claim that
  ScreenGuis curve in VR is [unverified]. Use Meta's numbers (`input-and-accessibility.md`).
- `VRService.LaserPointer` (Disabled, Pointer, DualPointer), `VRService.GuiInputUserCFrame`, and
  `VRService.AutomaticScaling` (world scale through HeadScale, not UI scale) [standard].
- The VR guidelines target 72 FPS or more on Quest and warn that "numerous and complex SurfaceGuis
  can be costly" [standard]. Putting VR menus on a few SurfaceGuis in front of the player is
  community practice [practitioner].
- Because the pointer and cursor are always on, every ScreenGui button must work with point and
  click and never depend on hover [inference].

## Console

Roblox's console guidance [standard]
([Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines)):

- Players sit 8-10 feet away; use relative sizes and detect TVs with `ViewportDisplaySize`.
- Keep key UI inside the TV-safe area, because "some TVs will not show content fully to the
  edges". **No margin figure is given**; the common 5% title-safe margin is industry habit
  [inference].
- Every element is reachable with directions, select, and back; key actions are a few presses
  away; menus use progressive disclosure; selection and movement play a sound; haptics are
  sparing.
- "Disable the chat window for console games", and console games must provide content maturity
  information.

## Content rules for UI text and images

- UI "may not link to, share, or display URLs of any external websites or services", and other
  efforts to direct users off Roblox are prohibited. The only allowed route is Social Links on the
  experience, group, or user page, for owners age-checked 16+ [standard]
  ([Community Standards](https://about.roblox.com/community-standards)). No Discord or YouTube
  handles, QR codes, or "join our server" text anywhere, loading screens included [inference].
- `PolicyService.AllowedExternalLinkReferences` always returns an empty array, so gating social
  links on it does nothing [standard].
- **Filter every displayed string the game doesn't fully control**: TextBox input, stored player
  text such as pet names, generated word combinations, web text. Call
  `TextService:FilterStringAsync` on the server, then `GetNonChatStringForBroadcastAsync` for
  everyone or `GetNonChatStringForUserAsync` for one viewer, on submit rather than per keystroke.
  Unfiltered experiences are removed until fixed [standard]
  ([Text filtering](https://create.roblox.com/docs/ui/text-filtering.md)). Design name fields to
  show the filtered result (hashtags) gracefully.
- Requesting personal information is prohibited [standard], so no UI asks for a real name, age,
  school, or location.
- UI imagery counts toward the experience's content maturity [standard].

## Costs that change a design

- A `CanvasGroup` that exceeds its texture memory cap renders blank, and the cap drops with the
  player's graphics quality, so low-end phones are where it fails [standard]. Fade groups of
  elements individually when that's cheap enough [inference].
- Small images stay under 256x256; icons share a sprite sheet [standard].
- A ScreenGui redraws as a whole when anything inside changes, so a timer or health bar that
  changes every frame lives in its own small ScreenGui (`roblox-dev:roblox-performance` `references/ui.md`,
  measured).
- A disabled ScreenGui doesn't render or take input, so closed menus cost nothing [standard].
