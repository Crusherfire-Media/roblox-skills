# Input and accessibility

Thresholds for touch, gamepad, mouse and keyboard, and VR, and the accessibility rules that apply
to every screen. Most hard numbers come from outside Roblox; `platform.md` has the Roblox APIs
that apply them.

## Thresholds

| Threshold | Value | Label and source |
|---|---|---|
| Adult one-thumb target | 9.2 mm single taps, 9.6 mm repeated taps | [study] [Parhi et al. 2006](https://dx.doi.org/10.1145/1152215.1152260) |
| Practical touch minimum | 1 cm; about 2 cm for primary targets; about 2 mm gaps | [practitioner] [NN/g](https://www.nngroup.com/articles/touch-target-size/) |
| WCAG 2.2 SC 2.5.8 (AA) | 24 x 24 CSS px, with a spacing exception | [standard] [W3C](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| WCAG 2.5.5, Apple, Material | 44 CSS px; 44 pt; 48 dp | [standard, not re-read from the primary pages] |
| Children's touch misses | 46% outside the target vs 32% for adults (ages 7-11) | [study] [Brown & Anthony 2012](https://lisa-anthony.com/wp-content/uploads/2012/03/brown-and-anthony-chi2012eist.pdf) |
| Console text | 26 px body height at 1080p, 52 px at 4K | [standard] [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101) |
| PC and VR text | 18 px at 1080p, 36 px at 4K | [standard] XAG 101 |
| Mobile text | 18 / 36 / 72 px at 100 / 200 / 400 DPI | [standard] XAG 101 |
| Text scaling | Up to 200% without lost content or two-way scrolling | [standard] XAG 101 |
| Contrast | 4.5:1 text and key visuals; 3:1 large or inactive; 7:1 high-contrast mode | [standard] [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102) |
| Subtitles | 46 px or more at 1080p, at most 40 characters a line, 2 lines, on a backplate | [practitioner] [GAG](https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/) |
| Flashing | At most 3 flashes in any second | [standard] WCAG 2.3.1 |
| VR text | 14 px minimum, 18 px or more comfortable; 48 dp targets | [standard] [Meta typography](https://developers.meta.com/horizon/design/styles_typography/) |

## Touch

- Size targets in physical millimetres. About 10 mm is enough for adult thumbs [study]; MIT Touch
  Lab measures fingertips at 16-20 mm and thumb contact around 25 mm [practitioner, via NN/g]. On
  a 400 DPI phone, 10 mm is about 157 physical pixels [inference].
- **Children need more.** They miss targets far more often than adults, gesture recognition is
  only about 84% accurate for ages 7-10 even when trained on children [study], and small targets
  at screen edges should be avoided [study] (Woodward et al., CHI 2016). Fitts's law predicts
  children's finger movement well (R² = 0.93), so bigger targets give predictable gains [study].
- The working rule for Roblox [inference]: 10 mm or more for any tap target, 15-20 mm for primary
  actions, a hit area larger than the visible graphic, and single taps instead of holds, swipes,
  or drawn gestures. The Game Accessibility Guidelines also warn against required holds and
  button mashing [practitioner].
- Most mobile players use two thumbs, one on the thumbstick and one on jump; keep "important info
  or virtual buttons" out of those corners [standard]
  ([Cross-platform design](https://create.roblox.com/docs/ui/cross-platform-design)). Roblox's
  sample puts a custom action button 20 px left of jump at 0.8 times its size, and shows contextual
  buttons only when relevant (a `ProximityPrompt` instead of a permanent button) [standard].
- In a 2021 landscape study the most comfortable left-thumb tap band was 27.5-41.3 mm from the
  thumb's pivot, with joystick centers at least 10 mm from the edges [study]
  ([arXiv 2110.08753](https://arxiv.org/pdf/2110.08753)). Hoober's thumb-zone diagram is portrait,
  non-game data from 2012-13 that its author says isn't "the one and only standard" [study,
  secondary].
- Menus, currency, and notifications go along the top or upper middle, clear of both thumbs
  [inference].

## Gamepad

XAG 112 [standard] ([XAG 112](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112)):

- The UI is "fully navigable by keyboard and controller digital input alone."
- Focus order follows meaning, then visual flow. Moves in a grid are spatial: Left goes to the
  tile directly left.
- **Linear lists wrap; 2-D grids don't need to.** Forza's grid example "should NOT loop".
- When text scaling reflows a layout, navigation order follows the new layout.
- Any element focus can reach must be leavable with the same input. Where that's impossible, as
  in a remap capture, say how to exit ("Press [ESC] to exit remapping mode").
- One mapping on every screen: **A select, B back, LB/RB tabs, LT/RT pages**, with prompts in a
  fixed place. Every submenu keeps a route back to the main screen.
- Large content (quest logs, big inventories) gets more than one way to find things, such as
  filter tabs plus search.
- Accessibility settings are reachable from first launch. XAG names younger players among those
  this consistency helps.

On Roblox [inference]: every screen sets a default selection with `GuiService:Select` so focus is
never lost when a gamepad connects; modals use a `SelectionGroup` with `Stop`; closing a screen
returns focus to the element that opened it; glyphs come from `GetImageForKeyCode` or
`InputActionLabel`. Rules for swapping confirm and back on Nintendo-style layouts, or Xbox versus
PlayStation glyph requirements, weren't found [unverified].

## Mouse and keyboard

- Menus work with keyboard alone (Tab or arrows plus Space or Enter), and a focusable Quit or
  Close exists for players who can't reach Esc [standard] (XAG 112). Controls are remappable
  [standard; practitioner].
- **Hover never holds the only path to information.** Touch and gamepad have no hover, so hover
  previews what focus or a tap also shows [inference].
- No sourced numbers exist for hover delay, tooltip timing, or scroll step.

## VR

- Meta: text at least 14 px for legibility and 18 px or more for comfort; 48 dp targets; panels
  small enough that users don't turn their heads, at a comfortable default size the user can
  enlarge, with important content in the field of view [standard]
  ([Meta panel sizing](https://developers.meta.com/horizon/essentials/horizon-os-panel-sizing/)).
- **"Headlocked menus and UI elements are generally uncomfortable for the user and should be
  avoided"**, except reticles and cockpits [standard]
  ([Meta VRC](https://developers.meta.com/horizon/resources/vrc-quest-functional-10/)).
- An AR study (not VR, not Meta) puts primary content in a 30 x 30 degree zone with about 15
  degrees of comfortable eye rotation and touch content at 0.4-0.6 m [study, by analogy only].
  Meta publishes no distance or degree figures.

## Accessibility rules for every screen

**Contrast.** Measure text against "the lowest contrasting area of the background" [standard]
(XAG 102). Over a 3D world a bare text color rarely passes everywhere, so HUD text and icons get a
semi-opaque backplate or a two-tone outline (For Honor's white text with a black outline is XAG's
example) [standard; inference]. An outline counts toward glyph height only where it contrasts more
than 2:1 with the background [standard] (XAG 101).

**Color.** Never use color alone. Color-coded information gets a second cue (shape, pattern,
icon, or text) or player-chosen colors; XAG uses item rarity as its own example [standard]
([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)).

**Text.** At least one sans-serif option and a plain alternative to stylized fonts, lines of 80
characters or fewer (40 CJK), 1.5 line spacing, sentence case instead of ALL CAPS for running
text, alignment by language rather than centered blocks, and no text baked into images [standard]
(XAG 101). Plain words a child knows; one idea per line [inference from NN/g].

**Motion.** Three flashes a second or fewer [standard]. Non-essential motion triggered by
interaction can be turned off [standard] (WCAG 2.3.3), which on Roblox means honoring
`ReducedMotionEnabled`. Avoid flicker, background motion, and sudden movement [practitioner,
GAG].

**Sound and time.** No information by sound alone; separate volumes for effects, speech, and
music [standard; practitioner]. Subtitles can be turned on before any sound plays, at a reading
speed that suits the target age [practitioner]. Time limits can be turned off, extended, or
adjusted at least tenfold [standard] (WCAG 2.2.1); menus don't run on a timer [inference].

**What to build first.** Remapping and subtitles were disabled players' top two requests
[practitioner]. On Roblox, text size, background transparency, and reduced motion come from the
player's Roblox settings, so the game honors them before adding its own [inference].
