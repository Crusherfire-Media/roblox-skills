# Components

Rules for each kind of screen element. Sources give strong rules for access (a second cue beside
color, digital navigation, timing, consistency) and weak ones for visual convention: no
peer-reviewed study compares inventory grids with lists, toast queues, or cooldown styles. Where a
rule is [inference] or [unverified], present it as a default to test.

## Contents

- HUD
- Menus, tabs, and navigation
- Inventories
- Settings
- Dialogs and confirmations
- Notifications and toasts
- Tooltips and details without hover
- Loading, errors, and disconnects
- Large numbers and timers

## HUD

- Fagerholt and Lorentzon (2009) sort UI into **diegetic** (in the fiction and the world),
  **non-diegetic** (overlay), **spatial** (in the world, not the fiction), and **meta** (in the
  fiction, not the world) [practitioner/academic]
  ([thesis](https://odr.chalmers.se/handle/20.500.12380/111921)). The taxonomy describes; it
  doesn't rank.
- The one controlled HUD comparison (Peacocke et al. 2015, five ammo displays): **a number in the
  world beside the weapon gave 26% faster reloads than HUD icons, 35% fewer shots fired while
  empty, and 70% preference** [study]
  ([paper](https://www.csit.carleton.ca/~rteather/pdfs/GEM2015_HUDs.pdf)). It was both diegetic
  and near where players looked, and the players were expert shooter players, so the lesson is
  proximity and numbers, not "diegetic is better" [inference].
- Keep essential short-lived information in the eye-line; let players recall the current
  objective and controls during play; let non-interactive HUD be hidden [practitioner]
  ([GAG](https://gameaccessibilityguidelines.com/full-list/)).
- Grounded pairs every meter's color with an icon and signals damage with a directional halo,
  sound, a low-health beep, and vibration; off-screen targets use audio pings that scale with
  distance (Gears 5) or highlight rings with spatial audio [standard] (XAG 103).
- Roblox asks for buttons that are easy to identify (contrasting containers, highlights, or
  shadows), one icon color and shape for related functions, and titles larger and bolder than body
  text [standard] ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
- Defaults [inference]: urgent state near the character or reticle; currency and the minimap in
  top corners outside the thumb regions; a number, or a number with a bar, for any count the
  player acts on; cooldowns as a sweep plus remaining seconds plus a ready cue (sound or flash).
- The simulator look (a left rail of chunky icon buttons, a currency bar, a bottom hotbar) shows
  up mostly in commercial UI packs copying top games: evidence of convention, not of preference
  [practitioner]. Use the convention for familiarity (players know where to look) and cut the rail
  to the buttons the player uses every session [inference].
- Ghost (trailing) damage bars, segmented bars, damage numbers, and hit-marker timing have no
  verified design source [unverified].

## Menus, tabs, and navigation

- Players can start playing "without the need to navigate through multiple levels of menus"
  [practitioner] (GAG basic). That's the only verified depth rule; "three levels at most" is
  folklore.
- Repeated components keep the same relative order on every screen, input mapping never changes
  between screens, and Back is always available with a visible prompt [standard] (XAG 112).
- Tabs switch with LB/RB on gamepad; screens announce their title on entry, and tabs announce
  role, position, and state ("Worlds, Tab, 1 of 3, selected") [standard]
  ([XAG 106](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/106)).
- Hick's law (decision time grows with the number of choices) supports a few primary choices per
  screen with one highlighted default. It models choosing among known options, so it doesn't argue
  against a long list that's sorted and searchable [study, via secondary; inference].
- One route per destination, because children find duplicate routes very confusing [study, via
  NN/g].
- A close button in the same top corner on every panel serves mouse and touch; on gamepad B closes,
  and the close button stays focusable [inference].

## Inventories

- Rarity shown by color also gets a frame shape, pip count, or tier word, or player-chosen colors
  [standard] (XAG 103).
- **Locked items need more than graying out**: Sea of Thieves adds chains and a lock; Forza adds
  "Not available" and a lock. Grounded marks a missing crafting ingredient four ways: red, a
  warning triangle, "x0 Available", and "Missing ingredients" [standard] (XAG 103).
- Large inventories get filter tabs plus search (Minecraft: four filter tabs and a search tab)
  [standard] (XAG 112), and slots announce their position ("6 of 9") [standard] (XAG 106).
- On gamepad and touch, drag and drop becomes **two presses: pick up, move, drop**, with a visible
  "carried" state while the D-pad moves the item [practitioner]
  ([Coherent Labs](https://guide.coherent-labs.com/logic-and-interactions/interactions/drag-and-drop/)).
  Back puts the item back where it came from [inference]. Roblox's `UIDragDetector` covers mouse
  and touch drags.
- Grids suit browsing (a 5 x 8 grid shows 40 items in the space a list gives 8-10); lists suit
  comparing and sorting [practitioner, low confidence].
- Children avoid scrolling, so a scrolling grid shows a partial row or another clear sign that more
  is there [study, via NN/g; inference].
- No verified sources cover slot sizes beyond touch minimums, where stack counts go, comparison
  panels, or full-inventory handling. Defaults [inference]: slots at least the touch minimum;
  stack counts bottom-right inside the slot with an outline; tapping an item selects it and shows
  details, and a second tap or a button uses it; a full inventory says so where the pickup
  happens, not only inside the inventory.

## Settings

- Expected (GAG basic): **separate volume for effects, speech, and music; control remapping;
  readable default text; high contrast; no color-only information; subtitles; settings that
  persist**. Intermediate: subtitles on before any sound, adjustable contrast, crosshair choice.
  Advanced: font size and settings profiles [practitioner]
  ([GAG](https://gameaccessibilityguidelines.com/full-list/)).
- Text size, background transparency, and reduced motion are Roblox settings, so the game honors
  them instead of adding its own copies [inference] (`platform.md`).
- Accessibility options are reachable from first launch, ideally on the first screen (Minecraft
  Dungeons), or met by default [standard] (XAG 112).
- Each setting row has a one-line description and announces name, type, value, and position
  ("Quality, drop down, collapsed, High, 3 of 9"). Offer "Reset to default" on one button (Forza's
  Y). **Saves show visible confirmation**, because pressing A and seeing nothing leaves players
  "unsure if their work has been saved" [standard] (XAG 106).
- Color-blind presets (deuteranopia, protanopia, tritanopia, high contrast) or per-category color
  pickers satisfy the color rules [standard] (XAG 103).
- Low-risk settings apply instantly with live preview. A setting that could leave the player
  unable to see or use the screen applies with "Keep changes / Revert" and reverts on its own,
  modeled on Windows' 15-second prompt [practitioner]. Resolution and display mode belong to the
  Roblox client, so this covers only game-owned options [inference].
- Settings persist across sessions (save them with the player's data) and live in a ScreenGui that
  survives respawn [inference] (`platform.md`).

## Dialogs and confirmations

- **Confirm only serious, irreversible actions; prefer undo.** Too many confirmations train
  people to click through ("if you cry wolf too many times, people will stop paying attention")
  [practitioner] ([NN/g](https://www.nngroup.com/articles/confirmation-dialog/)).
- Name the item and the result; label buttons with the outcome ("Delete pet" / "Keep pet"), never
  Yes/No; don't preselect the destructive option; save typed confirmation for rare, dangerous
  actions [practitioner].
- Prompts sit at the bottom of the dialog in a fixed order, B always backs out [standard] (XAG
  112), and error dialogs are read in full when they open [standard] (XAG 106).
- On Roblox [inference]: a `SelectionGroup` with `Stop`, first focus on the safe option, Back
  mapped to cancel, and a tap outside a destructive dialog cancels, never confirms.

## Notifications and toasts

- Auto-dismissing messages stay up **at least about 6 seconds**: Adobe Spectrum raises any lower
  timeout to 6 s and adds 1 s per extra 120 words; KDE found 3.5-4 s too short and moved to 7 s
  [practitioner] ([Spectrum](https://opensource.adobe.com/spectrum-web-components/components/toast/)).
- Time limits can be turned off, extended, or adjusted at least tenfold [standard] (WCAG 2.2.1).
- Notifications never take focus ("It's best to not change focus without player initiation"),
  can be narrated, and pair the visual with a sound; haptics may be a third channel, never the
  only one [standard] (XAG 106, XAG 103).
- One at a time, the rest queued [standard] (Android Snackbar).
- Working rule [inference]: show for `max(6 s, words / 3.5 per second + 1 s)`, scaled by a player
  setting where the game has one; one visible at a time; merge duplicates ("+3 coins" becomes
  "+9 coins"); place at the top or upper middle, clear of the thumbs and the screen center; never
  over a modal. Children read slowly, so 6 s is a floor.
- Roblox's own `SendNotification` appears bottom-right [standard]; custom toasts shouldn't stack
  on top of it.
- No verified standard covers maximum toast count, priority tiers, or a notification history.

## Tooltips and details without hover

- **Focus acts as hover.** The focused item's description shows in a fixed detail pane (Sea of
  Thieves) [standard] (XAG 106). Text labels beside icons "take the guesswork out" [standard]
  (XAG 103). Hodent: players should be challenged by the game, "not in trying to figure out what
  icons mean" [practitioner].
- On touch [inference]: the first tap selects and shows details, a second tap or a button acts.
  Long-press for info is invisible without a hint; `SecondaryActivated` is Roblox's long-press
  event [standard for the API].

## Loading, errors, and disconnects

- Announce start and finish ("Joining Realm", then "Done"), and update long waits every 7-10 s
  [standard] (XAG 106). Show a busy state past 1 s and progress with a cancel past 10 s
  [standard] ([NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/)).
- Errors lead with what happened and what to do [inference]. A disconnect or failed save says
  whether progress is safe and offers one primary action plus a safe exit [inference]. For
  children: one recovery button, not diagnostic text [inference from NN/g study].

## Large numbers and timers

- There's no standard past trillions. Games use K, M, B, T, then Qa and Qi, or letter codes (aa,
  ab) whose meaning differs from game to game, or scientific notation, which some idle-game players
  prefer [practitioner] ([Game Developer](https://gamedeveloper.com/design/names-of-large-numbers-for-idle-games)).
- Defaults [inference]: one documented suffix table for the whole game, about three significant
  digits so label width stays stable, a legend where suffixes go past T, and a scientific toggle
  in settings. "1.2K" may read differently to non-English players; CLDR compact number formats
  weren't checked [unverified].
- Countdowns update the narration every 7-10 s, and every second near zero [standard] (XAG 106).
  Show minutes and seconds (`2:05`) for anything over a minute [inference].
