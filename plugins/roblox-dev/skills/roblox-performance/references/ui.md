# UI

This file is about what the engine does with GuiObjects. How to write the UI itself is the
`vide` skill's job. Changes here that alter how UI looks or sizes itself (text scaling, view
distance, rounded corners) are for the user to approve.

## Design decisions

- **Split UI that changes often from UI that does not.** The engine caches the appearance of
  each `ScreenGui`, `SurfaceGui`, and `BillboardGui` as a whole and rebuilds all of it when
  anything inside changes. Put per-frame elements (timers, health bars, tweened pieces, damage
  numbers) in their own small ScreenGui. `[docs]` `[measured]`

  3,000 static labels plus one label changing every frame: `[measured]`

  | Where the changing label lives | Frame, ms | Render CPU, ms |
  |---|---|---|
  | Nothing changes | 16.8 | 8.3 |
  | Same ScreenGui, `Text` changes | 21.4 | 13.4 |
  | Same ScreenGui, `Position` changes | 28.3 | 13.5 |
  | Its own ScreenGui | 16.6 to 16.9 | 8.0 |

- **Reuse elements instead of destroying and re-creating them.** Every add, remove, reparent, or
  `ZIndex` change rebuilds the container's draw order. On a data change, update rows in place and
  add or remove only the difference. For 100 labels per frame: `[measured]`

  | Method | Script, ms |
  |---|---|
  | `Destroy` and re-create | 2.53 |
  | Reparent out and back | 0.78 |
  | Change `Text` on live labels | 0.23 |
  | Toggle `Visible` on reused labels | 0.10 |

- **Create only the rows a long list can show.** For lists past roughly a thousand items, keep a
  pool of rows the size of the window and fill them from the scroll position. Every child takes
  part in layout whether or not it is on screen. `[reported]` For hundreds of rows that carry
  state or animations, keeping each built and parenting only those near the window also works
  (the `vide-performance` skill).
- **Use a fixed `TextSize` with `AutomaticSize`, and a short list of fonts and sizes.** See
  "Text". `[docs]`
- **Budget in-world UI by count** and give every `BillboardGui` and `SurfaceGui` a finite
  `MaxDistance`. See "In-world UI". `[docs]`
- **In Vide, the rules here apply unchanged.** The engine cost of a property write
  (invalidation, layout) is the same whichever library makes it. Bind a changing value at the
  leaf, so a source change writes one property. `show` and `switch` destroy and rebuild their
  content; when to keep instances instead, and the Vide patterns for that, long lists, and
  CanvasGroups, are in the `vide-performance` skill.

## Text

- **All text shares one glyph atlas.** Every distinct combination of glyph, font, pixel size,
  and stroke on screen takes space in one texture. When it fills, glyphs are evicted and
  redrawn every frame, which shows as flickering or missing text, mostly on high-DPI phones.
  Roblox staff have given this diagnosis from 2018 through 2026. `[docs]`
- **`TextScaled` crowds the atlas and slows layout.** Each scaled label lands on its own pixel
  size, so the same glyphs are stored many times, and layout has to try several sizes: re-laying
  out a `TextScaled` label after a text change cost about 2.9x a fixed-size one.

  2,000 labels, every `Text` changed each frame: `[measured]`

  | Variant | Frame, ms | Above idle |
  |---|---|---|
  | No changes (any mode) | 16.7 | 0 |
  | Fixed `TextSize` | 30.6 | 14 |
  | `RichText` | 33.5 | 17 |
  | `AutomaticSize` | 35.9 | 19 |
  | `TextScaled` | 57.5 | 41 |

  Scaled text that does not change costs nothing per frame. Staff's current position: it is not
  forbidden, `AutomaticSize` with a fixed size is preferred, and when `TextScaled` is needed,
  bound it with a `UITextSizeConstraint`. Text sizes of 20 and above are readable on phones
  without it. `[docs]` The constraint's limits are real pixels: a `UIScale` above the label does
  not change them (the `vide` skill's `references/screens.md` has the numbers). `[measured]`
- **Never animate `TextSize` or a text `UIStroke`'s `Thickness`.** Every frame of the tween is a
  new set of glyphs in the atlas. Animate color, transparency, or position. `[docs]`
- **A `UIStroke` on text doubles the glyph images** (one for the letter, one for its outline). A
  `UIStroke` on a frame border is a shader and safe to animate. `[docs]`
- **On SurfaceGuis, lower `PixelsPerStud` instead of raising `TextSize`** to make text bigger.
  `[docs]`
- **Typewriter effects: set the full string once and animate `MaxVisibleGraphemes`.** Rewriting
  `Text` re-lays out the label on every step. `[docs]`
- Keep `UIGradient` and `UICorner` off text labels where possible: on text they add a separate
  effect pass per label. `[docs]`
- Turn `AutoLocalize` off on labels that show numbers, names, or generated text. Each `Text`
  write on a label with it on cost about 0.14 ms, in a translation lookup plus an engine
  telemetry call (`LocalizationService::attemptLocalization`, `Stat::send`). `[in-game]` Those
  labels then stay untranslated for players in other languages, so this is the user's call.

## Layout

- **Any resize or reposition re-runs layout for the affected tree**, including a tween of a
  `UIScale`. There is no cheap transform-only path. Tween properties that do not affect layout
  (colors, transparency) where the design allows. `[docs]`
- **Reading `AbsoluteSize`, `AbsolutePosition`, `AbsoluteContentSize`, or `TextBounds` forces
  any pending layout to run immediately.** In a loop that builds many items, set everything
  first and read afterward, instead of write, read, write, read. `[docs]`
- **A size animation fires every size listener inside it on every frame.** Each one reads the
  new size, and a listener that writes a property dirties layout for the next one's read. On one
  panel the first `AbsoluteSize` read after a `UIScale` step took 8 to 9.5 ms (the layout pass)
  and 98 more reads took 2.5 ms. Keep size listeners few in UI that scales, and have them write
  only when a scale-free value changes. `[in-game]`
- Avoid very deep nesting: a resize near the top touches much of the tree. `[docs]`
- Flex layout on a `UIListLayout` costs a little more than a plain list. Enable it where it is
  needed. `[docs]`
- **UI hidden with `Visible = false` is still laid out.** `Visible = false` and `Enabled = false`
  stop drawing, and staff described a 2026 engine fix for layout of hidden trees whose scope is
  not fully documented. `[docs]` In October 2026 a panel's layout pass after a scale step took
  9.2 ms with 53 off-screen cards as they were, 8.7 ms with them set to `Visible = false`, and
  1.2 ms with them unparented; `Enabled = false` was not measured. Take hidden content out of the
  tree when its layout shows in a profile, and stop tweens and per-frame writes on UI that is
  hidden. `[in-game]`
- **Text with `AutomaticSize` measured under a `UIScale` near 0 takes a wildly wrong size.**
  In one panel, labels built at the start of its grow-in measured their text width divided by the
  scale: 31 million pixels wide for 36 pixels of text, so they vanished off their rows. Visible
  labels were measured again as the scale grew. Labels in a page hidden with `Visible = false`
  kept that size when the page was shown, until a `UIScale` above them changed while they
  showed. A bare test did not reproduce the hidden case: labels measured at scales from 0.001
  down to 0, then hidden, scaled up, and shown came out right, with or without a list layout,
  rich text, a stroke, or a custom font. What else that panel had that triggers it was not found.
  Giving each page its own `UIScale`, 1 while shown and 1.0001 while hidden, fixed that panel:
  showing a page changes a scale above its text, so the engine measures the text again. The Vide
  version is in the `vide-performance` skill. `[in-game]`
- **ScreenGuis kept in `StarterGui` are cloned again on every spawn unless `ResetOnSpawn` is
  false.** Vide-built UI already sets it. `[docs]`
- Do not write every frame to value objects or attributes stored inside a ScreenGui: any
  descendant change invalidated the container's cache when staff last described it. `[docs]`

## Expensive features

- **`CanvasGroup`** allocates a texture the size of the group times the display scale, blurs or
  goes blank under memory pressure, and must not be resized every frame. All CanvasGroups share
  one texture budget capped by the client's quality level. Use it for group transparency or group
  effects, keep it small and fixed in size, and use a `Frame` otherwise. `[docs]` A hidden one may
  keep its texture until another claims it, and a new one can draw blank for its first frame.
  `[reported]` One being made or removed drew a white frame that faded content inside it did not
  hide; holding the group's own `GroupTransparency` near 1 at those moments hid it, apart from a
  barely visible flicker on small effects (`vide-performance` has the pattern). `[in-game]` One
  game with 366 CanvasGroups, almost all idle, flickered at low quality until each existed only
  while drawn, which left 20. `[in-game]`
- **`UIGradient`**: animate `Offset` or `Rotation`, not `Color` or `Transparency`, which rebuild
  the gradient. `[docs]`
- **`UICorner`** on a frame is a per-pixel cost that grows with the rounded area on screen. The
  numbers that made it look expensive are from an iPhone 6 in 2020; treat it as cheap unless
  large rounded areas overlap. `[reported]`
- **`ViewportFrame`** re-renders only when its camera or contents change, so a static one is
  cheap. To animate one, move the camera: moving the contents also rebuilds their geometry.
  Avoid many updating at once. `[docs]`
- **Images**: UI images are not covered by texture streaming, so size them for how large they
  appear (memory follows pixel count). Small icons can share a sprite sheet through
  `ImageRectOffset` and `ImageRectSize`. `[docs]`
- **UI draw calls batch only between neighbors in draw order.** Same-texture images share a draw
  call only when nothing different sits between them. A published test went from 288 UI draw
  calls to 22 by grouping same-sheet icons together. `[reported]`
- **Input hit-testing grows with the size and depth of the visible tree**, which matters on
  touch devices. `[docs]`

## In-world UI

- **Each `BillboardGui` and `SurfaceGui` is its own container** with its own cache, layout, and
  draw. Staff: "neither text nor billboard rendering is low impact." One report went from 240
  FPS to 90 to 150 with NPC name billboards on. `[docs]` `[reported]`
- **Set `MaxDistance` explicitly on every one.** `BillboardGui` defaults to no limit, and
  script-created SurfaceGuis are documented inconsistently. `[docs]`
- **Prefer fixed (offset) sizes for BillboardGuis.** A scale-sized billboard changes pixel size
  with camera distance, so its contents re-lay out, and scaled text is redrawn, whenever the
  camera moves. `[docs]`
- **A `Decal` or `Texture` is much cheaper than a `SurfaceGui` for a static image.** `[docs]`
- With thousands of in-world GUIs, do not assume that disabling them or `MaxDistance` makes
  them free. Measure, or pool and remove them. `[reported]`
- Humanoid name and health labels are in-world UI too, and they raycast for occlusion
  (`physics.md`). `[docs]`
- A huge transparent part behind in-world UI can draw over it, depending on where the camera
  faces. See `rendering.md`, "Transparency". `[in-game]`

## Measuring UI

The UI labels to look for are in the table at the end of `measuring.md`. For Vide UI, the
`vide-performance` skill's `references/finding-costs.md` adds probes for build spikes, layout,
text writes, CanvasGroups, and sounds. Reading a live client's dump is in `measuring.md`.
`Stats.RenderCPUFrameTime` is a usable quick check: it rose from 8 ms to 13 ms in the split test
above. UI costs are small per element and hide under the frame cap, so test with enough elements
to clear it.
